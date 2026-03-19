import Foundation

struct ConsumerProfile: Codable {
    let id: UUID?
    let userId: UUID
    let firstName: String?
    let lastName: String?
    let insuranceGoals: [String]
    let goalTimeline: String
    let preferredZip: String?
    let serviceMode: String
    let primaryGoal: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case insuranceGoals = "insurance_goals"
        case goalTimeline = "goal_timeline"
        case preferredZip = "preferred_zip"
        case serviceMode = "service_mode"
        case primaryGoal = "primary_goal"
    }
}
