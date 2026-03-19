import SwiftUI

struct ProfileHomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ProfileViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showPrivacySheet = false
    @State private var showTermsSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let userId = appState.authenticatedUserId {
                    content(userId: userId)
                } else {
                    guestState
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Authenticated Content

    private func content(userId: UUID) -> some View {
        List {
            // ── Header ──────────────────────────────────────
            Section {
                headerRow
            }

            // ── Stats ───────────────────────────────────────
            Section {
                statsRow
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            // ── Profile Details ─────────────────────────────
            Section {
                profileRow(label: "Categories", value: vm.categoriesLine)
                profileRow(label: "Location", value: vm.location)
                profileRow(label: "Specialties", value: vm.specialties)
                if !vm.userEmail.isEmpty {
                    profileRow(label: "Email", value: vm.userEmail)
                }
            } header: {
                Text("Profile")
            }

            // ── Actions ─────────────────────────────────────
            Section {
                Button {
                    appState.showOnboarding = true
                } label: {
                    Label("Edit RIA Profile", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.white)
                }
                .listRowBackground(Color.hushhPrimary)
            }

            // ── Legal ────────────────────────────────────────
            Section {
                Button {
                    showPrivacySheet = true
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)

                Button {
                    showTermsSheet = true
                } label: {
                    HStack {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)

                HStack {
                    Text("App Version")
                    Spacer()
                    Text(vm.appVersion)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Legal")
            }

            // ── Account ─────────────────────────────────────
            Section {
                Button(role: .destructive) {
                    Task {
                        await vm.signOut(appState: appState)
                    }
                } label: {
                    Text("Sign Out")
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    if vm.isDeleting {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.red)
                            Text("Deleting…")
                        }
                    } else {
                        Text("Delete Account")
                    }
                }
                .disabled(vm.isDeleting)
            } footer: {
                Text("Deleting your account permanently removes your profile, swipes, conversations, and all associated data.")
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showPrivacySheet) {
            LegalSheetView(
                title: "Privacy Policy",
                icon: "hand.raised.fill",
                content: """
                Last updated: March 2026

                Hushh Agents ("the App") is operated by Hushh.ai. We take your privacy seriously.

                Information We Collect
                • Name, email, and phone number you provide during onboarding
                • Profile photo you upload
                • Swipe activity (saved and passed agents)
                • Messages sent through in-app chat

                How We Use Your Data
                • To display your RIA profile to other users
                • To match you with relevant agents
                • To enable in-app messaging

                Storage & Security
                All data is stored securely on Supabase infrastructure with row-level security policies. Your data is never sold to third parties.

                Your Rights
                You can delete all your data at any time using the "Delete Account" option in your Profile. This permanently removes your profile, swipes, conversations, and uploaded photos.

                Contact
                privacy@hushh.ai
                """
            )
        }
        .sheet(isPresented: $showTermsSheet) {
            LegalSheetView(
                title: "Terms of Service",
                icon: "doc.text.fill",
                content: """
                Last updated: March 2026

                By using Hushh Agents, you agree to these terms.

                Eligibility
                You must be 18 or older and a licensed or aspiring Registered Investment Advisor (RIA) to use this app.

                Your Account
                You are responsible for maintaining the security of your account. Keep your sign-in credentials safe.

                Acceptable Use
                • Do not impersonate other professionals
                • Do not upload misleading or offensive content
                • Do not use the app for spam or solicitation

                Content Ownership
                You retain ownership of content you upload. By posting, you grant Hushh.ai a license to display it within the app.

                Disclaimers
                The app is provided "as is." We do not guarantee the accuracy of any user-submitted profiles or credentials.

                Account Deletion
                You may delete your account at any time. All associated data will be permanently removed.

                Contact
                legal@hushh.ai
                """
            )
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete My Account", role: .destructive) {
                Task {
                    await vm.deleteAccount(appState: appState)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your RIA profile, all swipes, conversations, messages, and your Hushh Agents account. This cannot be undone.")
        }
        .alert("Delete Failed", isPresented: Binding(
            get: { vm.deleteError != nil },
            set: { if !$0 { vm.deleteError = nil } }
        )) {
            Button("OK") { vm.deleteError = nil }
        } message: {
            Text(vm.deleteError ?? "")
        }
        .task(id: userId) {
            await vm.loadProfile(userId: userId)
            if let profile = vm.profile {
                appState.currentAgentProfile = profile
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: SwipeService.didChangeNotification)) { _ in
            Task {
                await vm.loadProfile(userId: userId)
                if let profile = vm.profile {
                    appState.currentAgentProfile = profile
                }
            }
        }
    }

    // MARK: - Header Row (Apple Settings style)

    private var headerRow: some View {
        VStack(spacing: 12) {
            // Centered avatar
            AsyncImage(url: vm.avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Color.hushhPrimary.opacity(0.12))
                        .overlay(
                            Text(vm.avatarInitials)
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.hushhPrimary)
                        )
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .id(vm.avatarURLString ?? vm.avatarInitials)

            // Centered info
            VStack(spacing: 4) {
                Text(vm.userName)
                    .font(.title2.bold())

                if !vm.businessName.isEmpty {
                    Text(vm.businessName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                Text(vm.roleLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                // Visibility badge
                Label(vm.visibilityLabel, systemImage: vm.visibilityLabel == "Discoverable" ? "eye.fill" : "eye.slash.fill")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(vm.visibilityLabel == "Discoverable" ? Color.green : Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill((vm.visibilityLabel == "Discoverable" ? Color.green : Color.orange).opacity(0.1))
                    )
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatCard(title: "Saved", value: "\(vm.selectedAgentsCount)", tint: .hushhLike)
            StatCard(title: "Passed", value: "\(vm.passedAgentsCount)", tint: .hushhPass)
            StatCard(title: "Chats", value: "\(vm.chatsCount)", tint: .hushhPrimary)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Profile Row

    private func profileRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Guest State

    private var guestState: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 54))
                .foregroundStyle(Color.hushhPrimary)

            Text("Sign in to publish your RIA profile, manage discovery, and keep your saved contacts in sync.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Sign In") {
                appState.showAuthSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.hushhPrimary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tint.opacity(0.1))
        )
    }
}

#Preview {
    ProfileHomeView()
        .environmentObject(AppState())
}
