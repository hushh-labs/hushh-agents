//
//  AuthService.swift
//  HushhAgents
//
//  Handles authentication via Supabase Auth (Apple, Google, session restore).
//

import Foundation
import Supabase

final class AuthService {
    struct UserProfile {
        let id: UUID
        let email: String?
        let fullName: String?
        let avatarURL: String?
    }

    private var auth: AuthClient {
        SupabaseService.shared.client.auth
    }

    // MARK: - Session Restore

    /// Attempts to restore an existing session.
    /// Returns `true` if a valid session was restored, `false` otherwise.
    func restoreSession() async throws -> Bool {
        do {
            _ = try await auth.session
            return true
        } catch {
            return false
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
    }

    // MARK: - Sign In with Google

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        try await auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }

    // MARK: - Sign In with Email and Password

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(email: email, password: password)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await auth.signOut()
    }

    // MARK: - Current User

    func currentUserId() async -> UUID? {
        guard let session = try? await auth.session else { return nil }
        return session.user.id
    }

    func currentUserProfile() async -> UserProfile? {
        guard let user = try? await auth.user() else { return nil }

        return UserProfile(
            id: user.id,
            email: user.email,
            fullName: firstNonEmpty(
                user.userMetadata["full_name"]?.stringValue,
                user.userMetadata["name"]?.stringValue,
                user.identities?.first?.identityData?["full_name"]?.stringValue,
                user.identities?.first?.identityData?["name"]?.stringValue
            ),
            avatarURL: firstNonEmpty(
                user.userMetadata["avatar_url"]?.stringValue,
                user.userMetadata["picture"]?.stringValue,
                user.identities?.first?.identityData?["avatar_url"]?.stringValue,
                user.identities?.first?.identityData?["picture"]?.stringValue
            )
        )
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.first { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } ?? nil
    }
}
