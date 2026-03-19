import Foundation

struct LeadRequest: Codable, Identifiable {
    let id: UUID?
    let userId: UUID
    let agentId: UUID
    let message: String
    let preferredChannel: String
    let urgency: String
    let status: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case agentId = "agent_id"
        case message
        case preferredChannel = "preferred_channel"
        case urgency
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
