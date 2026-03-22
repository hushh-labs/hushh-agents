import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var sessionStatus: SessionStatus = .anonymous
    @Published var onboardingStatus: OnboardingStatus = .incomplete
    @Published var onboardingPresentationMode: OnboardingPresentationMode = .initial
    @Published var pendingGatedAction: GatedAction? = nil
    @Published var currentUser: AppUser? = nil
    @Published var currentAgentProfile: HushhAgentProfile? = nil
    @Published var selectedTab: AppTab = .deck
    @Published var activitySection: ActivitySection = .saved
    @Published var requestedConversationAgentId: String? = nil
    @Published var showAuthSheet: Bool = false
    @Published var showOnboarding: Bool = false

    private let onboardingDeferralKeyPrefix = "deferred_onboarding_"
    private var requiresOnboardingAfterGuestAuth = false

    var isAuthenticated: Bool {
        if case .authenticated = sessionStatus { return true }
        return false
    }

    var isGuestBrowsingMode: Bool {
        !isAuthenticated
    }

    var authenticatedUserId: UUID? {
        guard case let .authenticated(userId) = sessionStatus else { return nil }
        return userId
    }

    var hasCompletedVerifiedProfile: Bool {
        onboardingStatus == .complete
    }

    var needsVerifiedProfileCompletion: Bool {
        isAuthenticated && !hasCompletedVerifiedProfile
    }

    var authenticatedIdentityName: String {
        if let fullName = trimmed(currentUser?.fullName) {
            return fullName
        }

        if let email = trimmed(currentUser?.email) {
            return email
        }

        return "Your account"
    }

    var authenticatedIdentityEmail: String? {
        let email = trimmed(currentUser?.email)
        guard let email else { return nil }
        return email == authenticatedIdentityName ? nil : email
    }

    var authenticatedIdentityAvatarURL: URL? {
        guard let avatarURL = trimmed(currentUser?.avatarUrl) else { return nil }
        return URL(string: avatarURL)
    }

    var authenticatedIdentityInitials: String {
        initials(from: authenticatedIdentityName)
    }

    var pendingDestinationLabel: String {
        destinationLabel(for: pendingGatedAction) ?? "Deck"
    }

    var onboardingPrimaryActionTitle: String {
        if onboardingPresentationMode == .editProfile {
            return "Update Profile"
        }

        if let destinationLabel = destinationLabel(for: pendingGatedAction) {
            return "Continue to \(destinationLabel)"
        }

        return "Continue to Deck"
    }

    func triggerGatedAction(_ action: GatedAction) {
        if isAuthenticated {
            pendingGatedAction = action
            resolveGatedAction()
        } else {
            presentGuestSignIn(for: action)
        }
    }

    func presentOnboarding(mode: OnboardingPresentationMode) {
        onboardingPresentationMode = mode
        showOnboarding = true
    }

    func presentGuestSignIn(for action: GatedAction? = nil) {
        requiresOnboardingAfterGuestAuth = true
        pendingGatedAction = action
        showAuthSheet = true
    }

    func handleAuthSheetDismissal() {
        guard !isAuthenticated else { return }
        requiresOnboardingAfterGuestAuth = false
        pendingGatedAction = nil
    }

    func resumeVerifiedProfileCompletion() {
        pendingGatedAction = nil
        requiresOnboardingAfterGuestAuth = false
        presentOnboarding(mode: .initial)
    }

    func resolveGatedAction() {
        guard let action = pendingGatedAction else { return }

        switch action {
        case .openActivity(let section):
            selectedTab = .activity
            activitySection = section
        case .openConversation(let agentId):
            selectedTab = .activity
            activitySection = .chats
            requestedConversationAgentId = agentId
        case .openProfile:
            selectedTab = .profile
        }

        pendingGatedAction = nil
    }

    func clearProtectedState() {
        sessionStatus = .anonymous
        onboardingStatus = .incomplete
        pendingGatedAction = nil
        currentUser = nil
        currentAgentProfile = nil
        selectedTab = .deck
        activitySection = .saved
        requestedConversationAgentId = nil
        requiresOnboardingAfterGuestAuth = false
        showAuthSheet = false
        showOnboarding = false
        onboardingPresentationMode = .initial
    }

    func handleAuthenticatedUser(_ user: AppUser) async {
        let userService = UserService()
        let shouldOnboardAfterAuth = requiresOnboardingAfterGuestAuth

        sessionStatus = .authenticated(userId: user.id)
        currentUser = user
        currentAgentProfile = try? await userService.fetchAgentProfile(userId: user.id)
        showAuthSheet = false

        let isComplete = user.onboardingStep == "complete" && (currentAgentProfile?.minimumRequiredFieldsComplete ?? false)
        onboardingStatus = isComplete ? .complete : .incomplete

        if onboardingStatus == .complete {
            setOnboardingDeferred(false, for: user.id)
            showOnboarding = false
            onboardingPresentationMode = .initial
            requiresOnboardingAfterGuestAuth = false
            resolveGatedAction()
        } else {
            onboardingPresentationMode = .initial
            if shouldOnboardAfterAuth {
                showOnboarding = true
            } else if pendingGatedAction != nil {
                showOnboarding = false
                resolveGatedAction()
            } else {
                showOnboarding = !isOnboardingDeferred(for: user.id)
            }
        }
    }

    func skipOnboarding() {
        if let userId = authenticatedUserId {
            setOnboardingDeferred(true, for: userId)
        }

        showOnboarding = false
        onboardingPresentationMode = .initial
        let shouldResolvePendingAction = pendingGatedAction != nil
        requiresOnboardingAfterGuestAuth = false

        if shouldResolvePendingAction {
            resolveGatedAction()
        } else {
            pendingGatedAction = nil
            selectedTab = .deck
        }
    }

    func completeOnboarding(with profile: HushhAgentProfile) {
        if let userId = authenticatedUserId {
            setOnboardingDeferred(false, for: userId)
        }

        onboardingStatus = .complete
        currentAgentProfile = profile
        showOnboarding = false
        let destinationMode = onboardingPresentationMode
        let shouldResolvePendingAction = pendingGatedAction != nil
        onboardingPresentationMode = .initial
        requiresOnboardingAfterGuestAuth = false

        if !shouldResolvePendingAction {
            selectedTab = destinationMode == .editProfile ? .profile : .deck
        }

        if let existingUser = currentUser {
            currentUser = existingUser.updating(
                phone: profile.phone.isEmpty ? existingUser.phone : profile.phone,
                fullName: displayName(from: profile) ?? existingUser.fullName,
                onboardingStep: "complete",
                profileVisibility: "discoverable",
                discoveryEnabled: true
            )
        }

        if shouldResolvePendingAction {
            resolveGatedAction()
        }
    }

    func checkSession() async {
        let authService = AuthService()
        let userService = UserService()

        do {
            let hasSession = try await authService.restoreSession()
            if hasSession, let userId = await authService.currentUserId() {
                sessionStatus = .authenticated(userId: userId)

                if let user = try await userService.fetchUser(id: userId) {
                    currentUser = user
                    currentAgentProfile = try? await userService.fetchAgentProfile(userId: userId)
                    let isComplete = user.onboardingStep == "complete" && (currentAgentProfile?.minimumRequiredFieldsComplete ?? false)
                    onboardingStatus = isComplete ? .complete : .incomplete
                    requiresOnboardingAfterGuestAuth = false

                    if onboardingStatus == .complete {
                        setOnboardingDeferred(false, for: userId)
                        showOnboarding = false
                        onboardingPresentationMode = .initial
                    } else if !isOnboardingDeferred(for: userId) {
                        onboardingPresentationMode = .initial
                        showOnboarding = true
                    }
                } else {
                    currentUser = nil
                    currentAgentProfile = nil
                    onboardingStatus = .incomplete
                    onboardingPresentationMode = .initial
                    requiresOnboardingAfterGuestAuth = false
                    showOnboarding = !isOnboardingDeferred(for: userId)
                }
            } else {
                sessionStatus = .anonymous
                currentUser = nil
                currentAgentProfile = nil
                pendingGatedAction = nil
                requiresOnboardingAfterGuestAuth = false
                showOnboarding = false
                onboardingPresentationMode = .initial
            }
        } catch {
            sessionStatus = .anonymous
            currentUser = nil
            currentAgentProfile = nil
            pendingGatedAction = nil
            requiresOnboardingAfterGuestAuth = false
            showOnboarding = false
            onboardingPresentationMode = .initial
            print("[AppState] Session restore failed: \(error.localizedDescription)")
        }
    }

    private func onboardingDeferralKey(for userId: UUID) -> String {
        onboardingDeferralKeyPrefix + userId.uuidString
    }

    private func isOnboardingDeferred(for userId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: onboardingDeferralKey(for: userId))
    }

    private func setOnboardingDeferred(_ deferred: Bool, for userId: UUID) {
        UserDefaults.standard.set(deferred, forKey: onboardingDeferralKey(for: userId))
    }

    func consumeRequestedConversationAgentId() -> String? {
        defer { requestedConversationAgentId = nil }
        return requestedConversationAgentId
    }

    private func displayName(from profile: HushhAgentProfile) -> String? {
        let representative = profile.representativeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !representative.isEmpty {
            return representative
        }

        let business = profile.businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        return business.isEmpty ? nil : business
    }

    private func destinationLabel(for action: GatedAction?) -> String? {
        guard let action else { return nil }

        switch action {
        case .openActivity(let section):
            return section.title
        case .openConversation:
            return "Chat"
        case .openProfile:
            return "Profile"
        }
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func initials(from value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return "HA" }

        let parts = trimmedValue.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }

        return String(trimmedValue.prefix(2)).uppercased()
    }
}
