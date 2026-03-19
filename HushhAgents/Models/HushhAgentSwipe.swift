import Foundation

struct HushhAgentSwipe: Codable, Identifiable, Equatable {
    let id: UUID?
    let actorUserId: UUID
    let targetKind: AgentTargetKind?
    let targetAgentId: String?
    let targetProfileUserId: UUID?
    let status: String
    let swipedAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case actorUserId = "actor_user_id"
        case targetKind = "target_kind"
        case targetAgentId = "target_agent_id"
        case targetProfileUserId = "target_profile_user_id"
        case status
        case swipedAt = "swiped_at"
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

    var agentId: String {
        deckTargetKey
    }
}
