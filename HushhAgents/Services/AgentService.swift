//
//  AgentService.swift
//  HushhAgents
//
//  Loads KirklandAgent data from Supabase with a local seed-file fallback.
//

import Foundation
import Supabase

final class AgentService {

    // MARK: - Fetch Agents

    /// Fetches agents from Supabase, falling back to the bundled seed JSON on failure.
    func fetchAgents() async -> [KirklandAgent] {
        do {
            let agents: [KirklandAgent] = try await SupabaseService.shared.client
                .from("kirkland_agents")
                .select()
                .order("avg_rating", ascending: false)
                .execute()
                .value
            return agents.map {
                $0.withTargetMetadata(kind: .catalog, catalogAgentId: $0.id, profileUserId: nil)
            }
        } catch {
            print("[AgentService] Remote fetch failed: \(error.localizedDescription). Loading from seed.")
            return loadFromSeed().map {
                $0.withTargetMetadata(kind: .catalog, catalogAgentId: $0.id, profileUserId: nil)
            }
        }
    }

    // MARK: - Fetch Discoverable User Profiles

    /// Fetches real user profiles that are discoverable, converts them to KirklandAgent format.
    func fetchDiscoverableProfiles(prioritizingUserId: UUID?) async -> [KirklandAgent] {
        guard prioritizingUserId != nil else { return [] }

        do {
            let profiles: [HushhAgentProfile] = try await SupabaseService.shared.client
                .from("hushh_agents_profiles")
                .select()
                .eq("discovery_enabled", value: true)
                .eq("profile_status", value: "discoverable")
                .order("updated_at", ascending: false)
                .execute()
                .value

            let prioritizedUserId = prioritizingUserId?.uuidString.lowercased()
            return profiles
                .compactMap { $0.toKirklandAgent() }
                .sorted { lhs, rhs in
                    let lhsIsCurrent = lhs.targetProfileUserId?.uuidString.lowercased() == prioritizedUserId
                    let rhsIsCurrent = rhs.targetProfileUserId?.uuidString.lowercased() == prioritizedUserId
                    if lhsIsCurrent != rhsIsCurrent {
                        return lhsIsCurrent && !rhsIsCurrent
                    }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
        } catch {
            print("[AgentService] Failed to fetch discoverable profiles: \(error.localizedDescription)")
            return []
        }
    }

    func fetchDeckAgents(prioritizingUserId: UUID?) async -> [KirklandAgent] {
        let catalogAgents = await fetchAgents()
        let discoverableProfiles = await fetchDiscoverableProfiles(prioritizingUserId: prioritizingUserId)

        var seen = Set<String>()
        return (discoverableProfiles + catalogAgents).filter { agent in
            seen.insert(agent.canonicalDeckIdentityKey).inserted
        }
    }

    // MARK: - Local Seed Fallback

    private func loadFromSeed() -> [KirklandAgent] {
        guard let url = Bundle.main.url(forResource: "Agents", withExtension: "json") else {
            print("[AgentService] Agents.json not found in bundle.")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            // New format: { metadata, agents } wrapper
            let seedData = try decoder.decode(AgentSeedData.self, from: data)
            print("[AgentService] Loaded \(seedData.agents.count) agents from seed.")
            return seedData.agents
        } catch {
            print("[AgentService] Failed to decode seed file: \(error)")
            return []
        }
    }
}
