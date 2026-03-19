import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var sessionStatus: SessionStatus = .anonymous
    @Published var onboardingStatus: OnboardingStatus = .incomplete
    @Published var pendingGatedAction: GatedAction? = nil
    @Published var currentUser: AppUser? = nil
    @Published var currentAgentProfile: HushhAgentProfile? = nil
    @Published var selectedTab: AppTab = .deck
    @Published var activitySection: ActivitySection = .saved
    @Published var requestedConversationAgentId: String? = nil
    @Published var showAuthSheet: Bool = false
    @Published var showOnboarding: Bool = false

    private let onboardingDeferralKeyPrefix = "deferred_onboarding_"

    var isAuthenticated: Bool {
        if case .authenticated = sessionStatus { return true }
        return false
    }

    var authenticatedUserId: UUID? {
        guard case let .authenticated(userId) = sessionStatus else { return nil }
        return userId
    }

    func triggerGatedAction(_ action: GatedAction) {
        if isAuthenticated {
            pendingGatedAction = action
            resolveGatedAction()
        } else {
            pendingGatedAction = action
            showAuthSheet = true
        }
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
        showAuthSheet = false
        showOnboarding = false
    }

    func handleAuthenticatedUser(_ user: AppUser) async {
        let userService = UserService()

        sessionStatus = .authenticated(userId: user.id)
        currentUser = user
        currentAgentProfile = try? await userService.fetchAgentProfile(userId: user.id)
        showAuthSheet = false

        let isComplete = user.onboardingStep == "complete" && (currentAgentProfile?.minimumRequiredFieldsComplete ?? false)
        onboardingStatus = isComplete ? .complete : .incomplete

        if onboardingStatus == .complete {
            setOnboardingDeferred(false, for: user.id)
            showOnboarding = false
            resolveGatedAction()
        } else {
            showOnboarding = pendingGatedAction != nil || !isOnboardingDeferred(for: user.id)
        }
    }

    func skipOnboarding() {
        if let userId = authenticatedUserId {
            setOnboardingDeferred(true, for: userId)
        }

        showOnboarding = false
        pendingGatedAction = nil
        selectedTab = .deck
    }

    func completeOnboarding(with profile: HushhAgentProfile) {
        if let userId = authenticatedUserId {
            setOnboardingDeferred(false, for: userId)
        }

        onboardingStatus = .complete
        currentAgentProfile = profile
        showOnboarding = false
        pendingGatedAction = nil
        selectedTab = .deck

        if let existingUser = currentUser {
            currentUser = existingUser.updating(
                phone: profile.phone.isEmpty ? existingUser.phone : profile.phone,
                fullName: displayName(from: profile) ?? existingUser.fullName,
                onboardingStep: "complete",
                profileVisibility: "discoverable",
                discoveryEnabled: true
            )
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

                    if onboardingStatus == .complete {
                        setOnboardingDeferred(false, for: userId)
                        showOnboarding = false
                    } else if !isOnboardingDeferred(for: userId) {
                        showOnboarding = true
                    }
                } else {
                    currentUser = nil
                    currentAgentProfile = nil
                    onboardingStatus = .incomplete
                    showOnboarding = !isOnboardingDeferred(for: userId)
                }
            } else {
                sessionStatus = .anonymous
                currentUser = nil
                currentAgentProfile = nil
                showOnboarding = false
            }
        } catch {
            sessionStatus = .anonymous
            currentUser = nil
            currentAgentProfile = nil
            showOnboarding = false
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
}
