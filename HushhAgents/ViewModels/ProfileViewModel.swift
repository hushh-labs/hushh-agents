import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: AppUser? = nil
    @Published var profile: HushhAgentProfile? = nil
    @Published var isLoading: Bool = true
    @Published var selectedAgentsCount: Int = 0
    @Published var passedAgentsCount: Int = 0
    @Published var chatsCount: Int = 0

    var userName: String {
        if let representativeName = trimmed(profile?.representativeName) {
            return representativeName
        }

        if let fullName = trimmed(user?.fullName) {
            return fullName
        }

        if let email = trimmed(user?.email) {
            return email
        }

        return "Your account"
    }

    var userEmail: String {
        user?.email ?? ""
    }

    var avatarInitials: String {
        let name = userName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var avatarURLString: String? {
        if let profilePhoto = trimmed(profile?.displayPhotoURLString) {
            return profilePhoto
        }

        return trimmed(user?.avatarUrl)
    }

    var avatarURL: URL? {
        guard let avatarURLString else { return nil }
        return URL(string: avatarURLString)
    }

    var businessName: String {
        let business = profile?.businessName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return business
    }

    var roleLine: String {
        trimmed(profile?.representativeRole) ?? ""
    }

    var categoriesLine: String {
        guard let categories = profile?.categories, !categories.isEmpty else { return "Not available yet" }
        return categories.map(Self.displayCategoryLabel(for:)).joined(separator: ", ")
    }

    var location: String {
        let city = profile?.city.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let state = profile?.state.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let zip = profile?.zip.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let joined = [city, state, zip].filter { !$0.isEmpty }.joined(separator: ", ")
        return joined.isEmpty ? "Not available yet" : joined
    }

    var specialties: String {
        let value = profile?.specialties.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Verified during public profile lookup." : value
    }

    var visibilityLabel: String {
        guard profile != nil else { return "" }
        if profile?.isDiscoverable == true {
            return "Discoverable"
        }
        return "Private"
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    func loadProfile(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        let userService = UserService()
        let swipeService = SwipeService()
        let chatService = ChatService()

        do {
            user = try await userService.fetchUser(id: userId)
            profile = try await userService.fetchAgentProfile(userId: userId)
            let selections = try await swipeService.fetchRemoteSelections(userId: userId)
            selectedAgentsCount = selections.filter { $0.status == "selected" }.count
            passedAgentsCount = selections.filter { $0.status == "rejected" }.count
            chatsCount = try await chatService.fetchConversations(ownerUserId: userId).count
        } catch {
            print("[ProfileViewModel] Failed to load profile: \(error.localizedDescription)")
        }
    }

    func signOut(appState: AppState) async {
        do {
            try await AuthService().signOut()
            appState.clearProtectedState()
        } catch {
            print("[ProfileViewModel] Failed to sign out: \(error.localizedDescription)")
        }
    }

    @Published var deleteError: String? = nil
    @Published var isDeleting: Bool = false

    func deleteAccount(appState: AppState) async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            // Call server-side RPC to delete all user data + auth user
            try await UserService().deleteAccount()
            // Clear all local state
            appState.clearProtectedState()
        } catch {
            deleteError = "Failed to delete account: \(error.localizedDescription)"
            print("[ProfileViewModel] Delete account failed: \(error)")
        }
    }

    private static func displayCategoryLabel(for rawValue: String) -> String {
        switch rawValue {
        case "wealth_management":
            return "Wealth Management"
        case "financial_planning":
            return "Financial Planning"
        case "investment_advisory":
            return "Investment Advisory"
        case "retirement_planning":
            return "Retirement Planning"
        case "tax_planning":
            return "Tax Planning"
        case "insurance":
            return "Insurance"
        default:
            return rawValue
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
