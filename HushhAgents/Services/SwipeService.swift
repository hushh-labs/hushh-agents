//
//  SwipeService.swift
//  HushhAgents
//
//  Manages swipe tracking: local guest queue (UserDefaults) and remote sync.
//

import Foundation
import Supabase

final class SwipeService {
    static let didChangeNotification = Notification.Name("HushhAgentsSwipeDidChange")

    private let guestSwipesKey = "guest_swipes"
    private let authenticatedSwipeCacheKeyPrefix = "hushh_agents_swipe_cache_"

    private struct CachedSwipe: Codable {
        let agentId: String?
        let targetKind: AgentTargetKind?
        let targetAgentId: String?
        let targetProfileUserId: UUID?
        let status: String
        let swipedAt: String

        var deckTargetKey: String {
            if let target = SwipeTarget(kind: resolvedTargetKind, targetAgentId: resolvedTargetAgentId, targetProfileUserId: resolvedTargetProfileUserId) {
                return target.deckTargetKey
            }
            return agentId ?? ""
        }

        private var resolvedTargetKind: AgentTargetKind {
            if let targetKind {
                return targetKind
            }
            if let agentId {
                return SwipeTarget.parseLegacyAgentId(agentId)?.kind ?? .catalog
            }
            return .catalog
        }

        private var resolvedTargetAgentId: String? {
            if let targetAgentId, !targetAgentId.isEmpty {
                return targetAgentId
            }
            if let agentId {
                return SwipeTarget.parseLegacyAgentId(agentId)?.targetAgentId
            }
            return nil
        }

        private var resolvedTargetProfileUserId: UUID? {
            if let targetProfileUserId {
                return targetProfileUserId
            }
            if let agentId {
                return SwipeTarget.parseLegacyAgentId(agentId)?.targetProfileUserId
            }
            return nil
        }
    }

    private struct PendingSwipe {
        let target: SwipeTarget
        let status: String
        let swipedAt: String?
    }

    private struct SwipeTarget {
        let kind: AgentTargetKind
        let targetAgentId: String?
        let targetProfileUserId: UUID?

        init?(agent: KirklandAgent) {
            switch agent.targetKind {
            case .catalog:
                guard let targetAgentId = agent.resolvedCatalogAgentId, !targetAgentId.isEmpty else {
                    return nil
                }
                self.kind = .catalog
                self.targetAgentId = targetAgentId
                self.targetProfileUserId = nil
            case .profile:
                guard let targetProfileUserId = agent.targetProfileUserId else {
                    return nil
                }
                self.kind = .profile
                self.targetAgentId = nil
                self.targetProfileUserId = targetProfileUserId
            }
        }

        init?(kind: AgentTargetKind, targetAgentId: String?, targetProfileUserId: UUID?) {
            switch kind {
            case .catalog:
                guard let targetAgentId, !targetAgentId.isEmpty else { return nil }
                self.kind = .catalog
                self.targetAgentId = targetAgentId
                self.targetProfileUserId = nil
            case .profile:
                guard let targetProfileUserId else { return nil }
                self.kind = .profile
                self.targetAgentId = nil
                self.targetProfileUserId = targetProfileUserId
            }
        }

        var deckTargetKey: String {
            switch kind {
            case .catalog:
                return "catalog:\(targetAgentId ?? "")"
            case .profile:
                return "profile:\(targetProfileUserId?.uuidString.lowercased() ?? "")"
            }
        }

        static func parseLegacyAgentId(_ rawValue: String) -> SwipeTarget? {
            if rawValue.hasPrefix("catalog:") {
                return SwipeTarget(
                    kind: .catalog,
                    targetAgentId: String(rawValue.dropFirst("catalog:".count)),
                    targetProfileUserId: nil
                )
            }

            if rawValue.hasPrefix("profile:") {
                return SwipeTarget(
                    kind: .profile,
                    targetAgentId: nil,
                    targetProfileUserId: UUID(uuidString: String(rawValue.dropFirst("profile:".count)))
                )
            }

            if rawValue.hasPrefix("profile_") {
                return SwipeTarget(
                    kind: .profile,
                    targetAgentId: nil,
                    targetProfileUserId: UUID(uuidString: String(rawValue.dropFirst("profile_".count)))
                )
            }

            return SwipeTarget(kind: .catalog, targetAgentId: rawValue, targetProfileUserId: nil)
        }
    }

    private struct SwipeRow: Encodable {
        let actorUserId: UUID
        let targetKind: String
        let targetAgentId: String?
        let targetProfileUserId: UUID?
        let status: String
        let swipedAt: String

        enum CodingKeys: String, CodingKey {
            case actorUserId = "actor_user_id"
            case targetKind = "target_kind"
            case targetAgentId = "target_agent_id"
            case targetProfileUserId = "target_profile_user_id"
            case status
            case swipedAt = "swiped_at"
        }
    }

    func queueGuestSwipe(agent: KirklandAgent, status: String) {
        guard let target = SwipeTarget(agent: agent) else { return }
        let swipedAt = ISO8601DateFormatter().string(from: Date())
        var swipes = loadRawPendingSwipes()
        swipes.removeAll { pendingSwipe(from: $0)?.target.deckTargetKey == target.deckTargetKey }
        swipes.append([
            "agentId": target.deckTargetKey,
            "targetKind": target.kind.rawValue,
            "targetAgentId": target.targetAgentId ?? "",
            "targetProfileUserId": target.targetProfileUserId?.uuidString.lowercased() ?? "",
            "status": status,
            "swipedAt": swipedAt
        ])
        UserDefaults.standard.set(swipes, forKey: guestSwipesKey)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    func clearPendingSwipes() {
        UserDefaults.standard.removeObject(forKey: guestSwipesKey)
    }

    func syncPendingSwipes(userId: UUID) async throws {
        let pending = loadPendingSwipes()
        guard !pending.isEmpty else { return }
        for swipe in pending {
            let resolvedSwipedAt = swipe.swipedAt ?? ISO8601DateFormatter().string(from: Date())
            cacheAuthenticatedSwipe(
                userId: userId,
                target: swipe.target,
                status: swipe.status,
                swipedAt: resolvedSwipedAt
            )
            _ = try await persistSwipe(
                userId: userId,
                target: swipe.target,
                status: swipe.status,
                swipedAt: resolvedSwipedAt
            )
        }

        clearPendingSwipes()
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    @discardableResult
    func applyOptimisticSwipe(userId: UUID, agent: KirklandAgent, status: String) -> String {
        guard let target = SwipeTarget(agent: agent) else {
            return ISO8601DateFormatter().string(from: Date())
        }
        let swipedAt = ISO8601DateFormatter().string(from: Date())
        cacheAuthenticatedSwipe(userId: userId, target: target, status: status, swipedAt: swipedAt)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        return swipedAt
    }

    func upsertSwipe(
        userId: UUID,
        agent: KirklandAgent,
        status: String,
        swipedAt: String? = nil,
        postsChangeNotification: Bool = true
    ) async throws -> HushhAgentSwipe {
        guard let target = SwipeTarget(agent: agent) else {
            throw NSError(domain: "SwipeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid swipe target"])
        }
        let resolvedSwipedAt = swipedAt ?? ISO8601DateFormatter().string(from: Date())
        cacheAuthenticatedSwipe(userId: userId, target: target, status: status, swipedAt: resolvedSwipedAt)
        if postsChangeNotification {
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }

        return try await persistSwipe(
            userId: userId,
            target: target,
            status: status,
            swipedAt: resolvedSwipedAt
        )
    }

    func fetchRemoteSelections(userId: UUID) async throws -> [HushhAgentSwipe] {
        let remoteSelections: [HushhAgentSwipe]
        do {
            remoteSelections = try await SupabaseService.shared.client
                .from("hushh_agents_agent_swipes")
                .select()
                .eq("actor_user_id", value: userId.uuidString)
                .order("swiped_at", ascending: false)
                .execute()
                .value
        } catch {
            let cachedSelections = loadCachedAuthenticatedSwipes(userId: userId)
            if !cachedSelections.isEmpty {
                return cachedSelections
            }
            throw error
        }

        let cachedSelections = loadCachedAuthenticatedSwipes(userId: userId)
        let mergedSelections = merge(remoteSelections: remoteSelections, cachedSelections: cachedSelections)
        persistCachedAuthenticatedSwipes(userId: userId, swipes: mergedSelections)
        return mergedSelections
    }

    private func loadRawPendingSwipes() -> [[String: String]] {
        (UserDefaults.standard.array(forKey: guestSwipesKey) as? [[String: String]]) ?? []
    }

    private func loadPendingSwipes() -> [PendingSwipe] {
        loadRawPendingSwipes().compactMap(pendingSwipe(from:))
    }

    private func pendingSwipe(from dict: [String: String]) -> PendingSwipe? {
        guard let status = dict["status"] else { return nil }

        let kind = dict["targetKind"].flatMap(AgentTargetKind.init(rawValue:))
        let targetAgentId = dict["targetAgentId"].flatMap { value in
            value.isEmpty ? nil : value
        }
        let targetProfileUserId = dict["targetProfileUserId"].flatMap(UUID.init(uuidString:))
        let legacyAgentId = dict["agentId"]

        let target: SwipeTarget?
        if let kind {
            target = SwipeTarget(
                kind: kind,
                targetAgentId: targetAgentId,
                targetProfileUserId: targetProfileUserId
            )
        } else if let legacyAgentId {
            target = SwipeTarget.parseLegacyAgentId(legacyAgentId)
        } else {
            target = nil
        }

        guard let target else { return nil }
        return PendingSwipe(target: target, status: status, swipedAt: dict["swipedAt"])
    }

    private func cacheAuthenticatedSwipe(userId: UUID, target: SwipeTarget, status: String, swipedAt: String) {
        var cached = loadCachedSwipeRows(userId: userId)
        cached.removeAll { $0.deckTargetKey == target.deckTargetKey }
        cached.append(
            CachedSwipe(
                agentId: target.deckTargetKey,
                targetKind: target.kind,
                targetAgentId: target.targetAgentId,
                targetProfileUserId: target.targetProfileUserId,
                status: status,
                swipedAt: swipedAt
            )
        )
        persistCachedSwipeRows(userId: userId, rows: cached)
    }

    private func loadCachedAuthenticatedSwipes(userId: UUID) -> [HushhAgentSwipe] {
        loadCachedSwipeRows(userId: userId).compactMap { cachedSwipe in
            guard let target = SwipeTarget(
                kind: cachedSwipe.targetKind ?? SwipeTarget.parseLegacyAgentId(cachedSwipe.agentId ?? "")?.kind ?? .catalog,
                targetAgentId: cachedSwipe.targetAgentId ?? SwipeTarget.parseLegacyAgentId(cachedSwipe.agentId ?? "")?.targetAgentId,
                targetProfileUserId: cachedSwipe.targetProfileUserId ?? SwipeTarget.parseLegacyAgentId(cachedSwipe.agentId ?? "")?.targetProfileUserId
            ) else {
                return nil
            }

            return HushhAgentSwipe(
                id: nil,
                actorUserId: userId,
                targetKind: target.kind,
                targetAgentId: target.targetAgentId,
                targetProfileUserId: target.targetProfileUserId,
                status: cachedSwipe.status,
                swipedAt: cachedSwipe.swipedAt,
                createdAt: cachedSwipe.swipedAt,
                updatedAt: cachedSwipe.swipedAt
            )
        }
    }

    private func loadCachedSwipeRows(userId: UUID) -> [CachedSwipe] {
        guard let data = UserDefaults.standard.data(forKey: authenticatedSwipeCacheKey(for: userId)),
              let rows = try? JSONDecoder().decode([CachedSwipe].self, from: data) else {
            return []
        }
        return rows
    }

    private func persistCachedAuthenticatedSwipes(userId: UUID, swipes: [HushhAgentSwipe]) {
        let rows: [CachedSwipe] = swipes.compactMap { swipe in
            guard let swipedAt = swipe.swipedAt ?? swipe.updatedAt ?? swipe.createdAt else { return nil }
            return CachedSwipe(
                agentId: swipe.deckTargetKey,
                targetKind: swipe.resolvedTargetKind,
                targetAgentId: swipe.targetAgentId,
                targetProfileUserId: swipe.targetProfileUserId,
                status: swipe.status,
                swipedAt: swipedAt
            )
        }
        persistCachedSwipeRows(userId: userId, rows: rows)
    }

    private func persistCachedSwipeRows(userId: UUID, rows: [CachedSwipe]) {
        guard let data = try? JSONEncoder().encode(rows) else { return }
        UserDefaults.standard.set(data, forKey: authenticatedSwipeCacheKey(for: userId))
    }

    private func authenticatedSwipeCacheKey(for userId: UUID) -> String {
        authenticatedSwipeCacheKeyPrefix + userId.uuidString
    }

    private func merge(remoteSelections: [HushhAgentSwipe], cachedSelections: [HushhAgentSwipe]) -> [HushhAgentSwipe] {
        func timestamp(for swipe: HushhAgentSwipe) -> String {
            swipe.swipedAt ?? swipe.updatedAt ?? swipe.createdAt ?? ""
        }

        var merged: [String: HushhAgentSwipe] = [:]

        for swipe in remoteSelections {
            merged[swipe.deckTargetKey] = swipe
        }

        for swipe in cachedSelections {
            if let existing = merged[swipe.deckTargetKey] {
                if timestamp(for: swipe) > timestamp(for: existing) {
                    merged[swipe.deckTargetKey] = swipe
                }
            } else {
                merged[swipe.deckTargetKey] = swipe
            }
        }

        return Array(merged.values)
    }

    private func persistSwipe(
        userId: UUID,
        target: SwipeTarget,
        status: String,
        swipedAt: String
    ) async throws -> HushhAgentSwipe {
        let row = SwipeRow(
            actorUserId: userId,
            targetKind: target.kind.rawValue,
            targetAgentId: target.targetAgentId,
            targetProfileUserId: target.targetProfileUserId,
            status: status,
            swipedAt: swipedAt
        )

        if let existingSwipe = try await fetchExistingSwipe(userId: userId, target: target) {
            if let existingId = existingSwipe.id {
                return try await SupabaseService.shared.client
                    .from("hushh_agents_agent_swipes")
                    .update(row)
                    .eq("id", value: existingId.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            }
        }

        return try await SupabaseService.shared.client
            .from("hushh_agents_agent_swipes")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
    }

    private func fetchExistingSwipe(userId: UUID, target: SwipeTarget) async throws -> HushhAgentSwipe? {
        switch target.kind {
        case .catalog:
            let swipes: [HushhAgentSwipe] = try await SupabaseService.shared.client
                .from("hushh_agents_agent_swipes")
                .select()
                .eq("actor_user_id", value: userId.uuidString)
                .eq("target_kind", value: target.kind.rawValue)
                .eq("target_agent_id", value: target.targetAgentId ?? "")
                .limit(1)
                .execute()
                .value
            return swipes.first
        case .profile:
            let swipes: [HushhAgentSwipe] = try await SupabaseService.shared.client
                .from("hushh_agents_agent_swipes")
                .select()
                .eq("actor_user_id", value: userId.uuidString)
                .eq("target_kind", value: target.kind.rawValue)
                .eq("target_profile_user_id", value: target.targetProfileUserId?.uuidString.lowercased() ?? "")
                .limit(1)
                .execute()
                .value
            return swipes.first
        }
    }
}
