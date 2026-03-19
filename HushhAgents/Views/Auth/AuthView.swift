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
        VStack(spacing: 0) {
            Spacer()

            // MARK: – Logo & Title
            VStack(spacing: 16) {
                Image("HushhLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Hushh Agents")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)

                Text("A private RIA discovery network")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // MARK: – Sign In Buttons
            VStack(spacing: 14) {
                // Sign in with Apple (native button - white style for light mode)
                SignInWithAppleButton(.signIn) { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Maybe Later (skip)
                Button {
                    dismiss()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                .disabled(authVM.isLoading)
            }
            .padding(.horizontal, 32)

            // MARK: – Footer
            Text("By signing in, you agree to our Privacy Policy and Terms of Service.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .alert("Sign In Error", isPresented: Binding(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.errorMessage = nil } }
        )) {
            Button("OK") { authVM.errorMessage = nil }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
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

#Preview {
    AuthView()
        .environmentObject(AppState())
}
