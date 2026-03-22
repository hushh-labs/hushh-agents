import Foundation

enum AppTab: Hashable {
    case deck
    case activity
    case profile
}

enum ActivitySection: String, CaseIterable, Identifiable {
    case saved
    case passed
    case chats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .saved:
            return "Saved"
        case .passed:
            return "Passed"
        case .chats:
            return "Chats"
        }
    }
}

enum GatedAction: Equatable {
    case openActivity(section: ActivitySection)
    case openConversation(agentId: String)
    case openProfile
}

enum SessionStatus: Equatable {
    case anonymous
    case authenticated(userId: UUID)
}

enum OnboardingStatus: Equatable {
    case incomplete
    case complete
}

enum OnboardingPresentationMode: Equatable {
    case initial
    case editProfile
}
