import SwiftUI
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Auth View
struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authVM = AuthViewModel()

    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            authBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    authHero
                    guestBenefitsCard
                    signInCard

                    Text("By signing in, you agree to our Privacy Policy and Terms of Service.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .alert("Sign In Error", isPresented: Binding(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.errorMessage = nil } }
        )) {
            Button("OK") { authVM.errorMessage = nil }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }

    private var authSubtitle: String {
        if appState.pendingGatedAction != nil {
            return "Sign in to unlock \(appState.pendingDestinationLabel.lowercased()) and keep the deck activity you already started."
        }

        return "Sign in to sync your deck activity and start building your verified advisor profile."
    }

    private var authBackground: some View {
        ZStack {
            Color(.systemGroupedBackground)

            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.hushhPrimary.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 30)
                .offset(x: 150, y: -220)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 240, height: 240)
                .blur(radius: 20)
                .offset(x: -150, y: -130)
        }
        .ignoresSafeArea()
    }

    private var authHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 88, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )

                Image("HushhLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("Hushh Agents")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)

                Text(authSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var guestBenefitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What happens next")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            AuthFeatureRow(
                icon: "arrow.trianglehead.clockwise",
                title: "Guest swipes sync to your account",
                message: "The saved and passed activity you already created stays with you once you sign in."
            )

            AuthFeatureRow(
                icon: "person.crop.circle.badge.checkmark",
                title: "Verified profile setup comes next",
                message: onboardingFollowUpText
            )
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }

    private var signInCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Sign in with Apple to continue")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Your Hushh account stays simple: one sign-in, one verified identity, and your activity follows you across the app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                dismiss()
            } label: {
                Text("Maybe Later")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground).opacity(0.88))
                    )
            }
            .buttonStyle(.plain)
            .disabled(authVM.isLoading)
            .opacity(authVM.isLoading ? 0.55 : 1)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
    }

    private var onboardingFollowUpText: String {
        if appState.pendingGatedAction != nil {
            return "After sign-in, you’ll verify your profile before continuing to \(appState.pendingDestinationLabel.lowercased())."
        }

        return "After sign-in, you’ll verify your public advisor profile before the rest of the app reflects your identity."
    }

    // MARK: - Apple Sign In Handler

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                return
            }

            Task {
                let user = await authVM.signInWithApple(
                    idToken: identityToken,
                    nonce: nonce,
                    email: appleIDCredential.email,
                    fullName: formattedFullName(from: appleIDCredential.fullName)
                )
                if let user {
                    finishSignIn(with: user)
                }
            }

        case .failure(let error):
            // User cancelled or other error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authVM.errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func finishSignIn(with user: AppUser) {
        Task {
            await appState.handleAuthenticatedUser(user)
            // No dismiss() — handleAuthenticatedUser() sets showAuthSheet=false
        }
    }

    private func formattedFullName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }

        let formatter = PersonNameComponentsFormatter()
        let fullName = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
        return fullName.isEmpty ? nil : fullName
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in charset[Int(byte) % charset.count] }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

private struct AuthFeatureRow: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.hushhPrimary.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hushhPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
}
