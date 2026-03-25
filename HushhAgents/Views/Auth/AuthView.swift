import SwiftUI
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Auth View

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authVM = AuthViewModel()
    @FocusState private var isPasscodeFieldFocused: Bool

    @State private var currentNonce: String?
    @State private var adminPasscode = ""

    var body: some View {
        NavigationStack {
            Form {
                // Hero section
                Section {
                    VStack(spacing: 14) {
                        Image("HushhLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("Hushh Agents")
                            .font(.title.bold())

                        Text(authSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // What happens next
                Section("What happens next") {
                    if isInternalAdminMode {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unlock the full app instantly")
                                    .font(.subheadline.weight(.medium))
                                Text("The passcode signs you into the shared test account.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "lock.open.fill")
                                .foregroundStyle(.blue)
                        }

                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Database-backed flows stay live")
                                    .font(.subheadline.weight(.medium))
                                Text("Deck, activity, chats, and profile data use the normal Supabase session.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "server.rack")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Guest swipes sync to your account")
                                    .font(.subheadline.weight(.medium))
                                Text("Saved and passed activity stays with you once you sign in.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.trianglehead.clockwise")
                                .foregroundStyle(.blue)
                        }

                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verified profile setup comes next")
                                    .font(.subheadline.weight(.medium))
                                Text(onboardingFollowUpText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }

                // Sign In section
                Section {
                    if isInternalAdminMode {
                        SecureField("Enter internal passcode", text: $adminPasscode)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($isPasscodeFieldFocused)
                            .onSubmit {
                                submitAdminPasscode()
                            }
                    }
                } header: {
                    Text(isInternalAdminMode ? "Internal Test Access" : "Sign In")
                } footer: {
                    Text(signInFooterMessage)
                }

                // Action buttons
                Section {
                    if isInternalAdminMode {
                        Button {
                            submitAdminPasscode()
                        } label: {
                            HStack {
                                Spacer()
                                if authVM.isLoading {
                                    ProgressView()
                                        .padding(.trailing, 6)
                                }
                                Text(authVM.isLoading ? "Unlocking…" : "Unlock App")
                                    .font(.body.weight(.semibold))
                                Spacer()
                            }
                        }
                        .disabled(authVM.isLoading || adminPasscode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    Button("Maybe Later", role: .cancel) {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(authVM.isLoading)
                }

                // Legal footer
                Section {
                    Text("By signing in, you agree to our Privacy Policy and Terms of Service.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
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
        if isInternalAdminMode {
            if appState.pendingGatedAction != nil {
                return "Enter the internal passcode to unlock \(appState.pendingDestinationLabel.lowercased()) with the shared test account."
            }
            return "Enter the internal passcode to unlock the full app with shared test data."
        }

        if appState.pendingGatedAction != nil {
            return "Sign in to unlock \(appState.pendingDestinationLabel.lowercased()) and keep the deck activity you already started."
        }

        return "Sign in to sync your deck activity and start building your verified advisor profile."
    }

    private var signInFooterMessage: String {
        if isInternalAdminMode {
            return "Use the shared internal passcode to enter the full app. The hidden shared account keeps database-backed features working like a normal signed-in session."
        }
        return "Your Hushh account stays simple: one sign-in, one verified identity."
    }

    private var isInternalAdminMode: Bool {
        appState.isInternalAdminAuthModeEnabled
    }

    private var onboardingFollowUpText: String {
        if appState.pendingGatedAction != nil {
            return "After sign-in, you'll verify your profile before continuing."
        }
        return "After sign-in, you'll verify your public advisor profile."
    }

    private func submitAdminPasscode() {
        guard isInternalAdminMode else { return }
        isPasscodeFieldFocused = false
        Task {
            let user = await authVM.signInWithAdminPasscode(passcode: adminPasscode)
            if let user {
                adminPasscode = ""
                finishSignIn(with: user)
            }
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
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authVM.errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func finishSignIn(with user: AppUser) {
        Task {
            await appState.handleAuthenticatedUser(user)
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
