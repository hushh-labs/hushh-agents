import Foundation

struct UserAgentSelection: Codable, Identifiable {
    let id: UUID?
    let userId: UUID
    let agentId: String
    let status: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case agentId = "agent_id"
        case status
        case createdAt = "created_at"
    }
}
