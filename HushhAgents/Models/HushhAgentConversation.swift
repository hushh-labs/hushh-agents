import Foundation

struct HushhAgentConversation: Codable, Identifiable, Equatable {
    let id: UUID
    let ownerUserId: UUID
    let targetKind: AgentTargetKind?
    let targetAgentId: String?
    let targetProfileUserId: UUID?
    let targetAgentName: String
    let targetAgentLocation: String
    let targetAgentPhotoURL: String?
    let status: String
    let lastMessagePreview: String?
    let lastMessageAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case targetKind = "target_kind"
        case targetAgentId = "target_agent_id"
        case targetProfileUserId = "target_profile_user_id"
        case targetAgentName = "target_agent_name"
        case targetAgentLocation = "target_agent_location"
        case targetAgentPhotoURL = "target_agent_photo_url"
        case status
        case lastMessagePreview = "last_message_preview"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var resolvedTargetKind: AgentTargetKind {
        if let targetKind {
            return targetKind
        }
        return targetProfileUserId == nil ? .catalog : .profile
    }

    var deckTargetKey: String {
        switch resolvedTargetKind {
        case .catalog:
            return "catalog:\(targetAgentId ?? "")"
        case .profile:
            return "profile:\(targetProfileUserId?.uuidString.lowercased() ?? "")"
        }
    }
}

struct HushhAgentMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let conversationId: UUID
    let ownerUserId: UUID
    let senderRole: String
    let body: String
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case ownerUserId = "owner_user_id"
        case senderRole = "sender_role"
        case body
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
