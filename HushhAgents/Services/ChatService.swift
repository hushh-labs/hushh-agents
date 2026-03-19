import Foundation
import Supabase

final class ChatService {
    private struct ConversationTarget {
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
    }

    func ensureConversation(ownerUserId: UUID, agent: KirklandAgent) async throws -> HushhAgentConversation {
        let conversation = try await upsertConversation(
            ownerUserId: ownerUserId,
            agent: agent,
            status: "active"
        )

        let existingMessages = try await fetchMessages(conversationId: conversation.id)
        if existingMessages.isEmpty {
            _ = try? await sendSystemMessage(
                conversationId: conversation.id,
                ownerUserId: ownerUserId,
                body: "You saved \(agent.name). Use this space for notes, next steps, and outreach drafts."
            )
        }

        return conversation
    }

    @discardableResult
    func archiveConversation(ownerUserId: UUID, agent: KirklandAgent) async throws -> HushhAgentConversation? {
        struct ConversationStatusRow: Encodable {
            let status: String
        }

        guard let target = ConversationTarget(agent: agent) else { return nil }

        let archivedRows: [HushhAgentConversation]
        switch target.kind {
        case .catalog:
            archivedRows = try await SupabaseService.shared.client
                .from("hushh_agents_conversations")
                .update(ConversationStatusRow(status: "archived"))
                .eq("owner_user_id", value: ownerUserId.uuidString)
                .eq("target_kind", value: target.kind.rawValue)
                .eq("target_agent_id", value: target.targetAgentId ?? "")
                .select()
                .execute()
                .value
        case .profile:
            archivedRows = try await SupabaseService.shared.client
                .from("hushh_agents_conversations")
                .update(ConversationStatusRow(status: "archived"))
                .eq("owner_user_id", value: ownerUserId.uuidString)
                .eq("target_kind", value: target.kind.rawValue)
                .eq("target_profile_user_id", value: target.targetProfileUserId?.uuidString.lowercased() ?? "")
                .select()
                .execute()
                .value
        }

        return archivedRows.first
    }

    func fetchConversations(ownerUserId: UUID, includeArchived: Bool = false) async throws -> [HushhAgentConversation] {
        if includeArchived {
            return try await SupabaseService.shared.client
                .from("hushh_agents_conversations")
                .select()
                .eq("owner_user_id", value: ownerUserId.uuidString)
                .order("last_message_at", ascending: false)
                .execute()
                .value
        }

        return try await SupabaseService.shared.client
            .from("hushh_agents_conversations")
            .select()
            .eq("owner_user_id", value: ownerUserId.uuidString)
            .eq("status", value: "active")
            .order("last_message_at", ascending: false)
            .execute()
            .value
    }

    func fetchMessages(conversationId: UUID) async throws -> [HushhAgentMessage] {
        try await SupabaseService.shared.client
            .from("hushh_agents_messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    @discardableResult
    func sendOwnerMessage(conversationId: UUID, ownerUserId: UUID, body: String) async throws -> HushhAgentMessage {
        try await sendMessage(
            conversationId: conversationId,
            ownerUserId: ownerUserId,
            senderRole: "owner",
            body: body
        )
    }

    @discardableResult
    func sendSystemMessage(conversationId: UUID, ownerUserId: UUID, body: String) async throws -> HushhAgentMessage {
        try await sendMessage(
            conversationId: conversationId,
            ownerUserId: ownerUserId,
            senderRole: "system",
            body: body
        )
    }

    private func sendMessage(
        conversationId: UUID,
        ownerUserId: UUID,
        senderRole: String,
        body: String
    ) async throws -> HushhAgentMessage {
        struct MessageRow: Encodable {
            let conversationId: UUID
            let ownerUserId: UUID
            let senderRole: String
            let body: String

            enum CodingKeys: String, CodingKey {
                case conversationId = "conversation_id"
                case ownerUserId = "owner_user_id"
                case senderRole = "sender_role"
                case body
            }
        }

        return try await SupabaseService.shared.client
            .from("hushh_agents_messages")
            .insert(
                MessageRow(
                    conversationId: conversationId,
                    ownerUserId: ownerUserId,
                    senderRole: senderRole,
                    body: body
                )
            )
            .select()
            .single()
            .execute()
            .value
    }

    private func upsertConversation(
        ownerUserId: UUID,
        agent: KirklandAgent,
        status: String
    ) async throws -> HushhAgentConversation {
        guard let target = ConversationTarget(agent: agent) else {
            throw NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid conversation target"])
        }

        struct ConversationRow: Encodable {
            let ownerUserId: UUID
            let targetKind: String
            let targetAgentId: String?
            let targetProfileUserId: UUID?
            let targetAgentName: String
            let targetAgentLocation: String
            let targetAgentPhotoURL: String?
            let status: String

            enum CodingKeys: String, CodingKey {
                case ownerUserId = "owner_user_id"
                case targetKind = "target_kind"
                case targetAgentId = "target_agent_id"
                case targetProfileUserId = "target_profile_user_id"
                case targetAgentName = "target_agent_name"
                case targetAgentLocation = "target_agent_location"
                case targetAgentPhotoURL = "target_agent_photo_url"
                case status
            }
        }

        let row = ConversationRow(
            ownerUserId: ownerUserId,
            targetKind: target.kind.rawValue,
            targetAgentId: target.targetAgentId,
            targetProfileUserId: target.targetProfileUserId,
            targetAgentName: agent.name,
            targetAgentLocation: [agent.city, agent.state].compactMap { $0 }.joined(separator: ", "),
            targetAgentPhotoURL: agent.primaryPhotoURL?.absoluteString,
            status: status
        )

        if let existingConversation = try await fetchExistingConversation(ownerUserId: ownerUserId, target: target) {
            return try await SupabaseService.shared.client
                .from("hushh_agents_conversations")
                .update(row)
                .eq("id", value: existingConversation.id.uuidString)
                .select()
                .single()
                .execute()
                .value
        }

        return try await SupabaseService.shared.client
            .from("hushh_agents_conversations")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
    }

    private func fetchExistingConversation(
        ownerUserId: UUID,
        target: ConversationTarget
    ) async throws -> HushhAgentConversation? {
        switch target.kind {
        case .catalog:
            let conversations: [HushhAgentConversation] = try await SupabaseService.shared.client
                .from("hushh_agents_conversations")
                .select()
                .eq("owner_user_id", value: ownerUserId.uuidString)
                .eq("target_kind", value: target.kind.rawValue)
                .eq("target_agent_id", value: target.targetAgentId ?? "")
                .limit(1)
                .execute()
                .value
            return conversations.first
        case .profile:
            let conversations: [HushhAgentConversation] = try await SupabaseService.shared.client
                .from("hushh_agents_conversations")
                .select()
                .eq("owner_user_id", value: ownerUserId.uuidString)
                .eq("target_kind", value: target.kind.rawValue)
                .eq("target_profile_user_id", value: target.targetProfileUserId?.uuidString.lowercased() ?? "")
                .limit(1)
                .execute()
                .value
            return conversations.first
        }
    }
}
