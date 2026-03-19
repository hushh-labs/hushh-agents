import Foundation

/// ViewModel for the authentication screen (Apple + Google Sign In).
@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let authService = AuthService()
    private let userService = UserService()
    private let swipeService = SwipeService()

    // MARK: - Sign In with Apple

    func signInWithApple(idToken: String, nonce: String, email: String?, fullName: String?) async -> AppUser? {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signInWithApple(idToken: idToken, nonce: nonce)
            return try await finalizeSignIn(
                fallbackEmail: email,
                fallbackFullName: fullName,
                fallbackAvatarURL: nil
            )
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    // MARK: - Sign In with Google

    func signInWithGoogle(
        idToken: String,
        accessToken: String,
        email: String?,
        fullName: String?,
        avatarURL: String?
    ) async -> AppUser? {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken)
            return try await finalizeSignIn(
                fallbackEmail: email,
                fallbackFullName: fullName,
                fallbackAvatarURL: avatarURL
            )
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finalizeSignIn(
        fallbackEmail: String?,
        fallbackFullName: String?,
        fallbackAvatarURL: String?
    ) async throws -> AppUser? {
        let profile = await authService.currentUserProfile()
        let resolvedUserId: UUID?

        if let profileId = profile?.id {
            resolvedUserId = profileId
        } else {
            resolvedUserId = await authService.currentUserId()
        }

        guard let userId = resolvedUserId else {
            isLoading = false
            return nil
        }

        let user = try await userService.upsertUser(
            id: userId,
            email: preferredValue(fallbackEmail, profile?.email),
            fullName: preferredValue(fallbackFullName, profile?.fullName),
            avatarUrl: preferredValue(fallbackAvatarURL, profile?.avatarURL)
        )

        try? await swipeService.syncPendingSwipes(userId: userId)

        isLoading = false
        return user
    }

    private func preferredValue(_ primary: String?, _ secondary: String?) -> String? {
        if let primary, !primary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return primary
        }

        if let secondary, !secondary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return secondary
        }

        return nil
    }
}
