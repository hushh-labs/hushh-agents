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
        Form {
            // Profile Header
            Section {
                if appState.needsVerifiedProfileCompletion {
                    incompleteHeaderRow
                } else {
                    headerRow
                }
            }

            // Complete profile prompt
            if appState.needsVerifiedProfileCompletion {
                Section {
                    VerifiedProfileCompletionCard(
                        title: "Complete your verified profile",
                        message: "Resume your lookup so the app reflects your real advisor identity.",
                        buttonTitle: "Resume Lookup",
                        style: .compact
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Stats
            if hasRecordedActivity {
                Section("Activity") {
                    HStack(spacing: 0) {
                        statItem(title: "Saved", value: "\(vm.selectedAgentsCount)", tint: .green)
                        Divider()
                        statItem(title: "Passed", value: "\(vm.passedAgentsCount)", tint: .red)
                        Divider()
                        statItem(title: "Chats", value: "\(vm.chatsCount)", tint: .blue)
                    }
                }
            }

            // Profile details (only if complete)
            if !appState.needsVerifiedProfileCompletion {
                Section("Details") {
                    profileDetailRow("Categories", value: vm.categoriesLine)
                    profileDetailRow("Location", value: vm.location)
                    profileDetailRow("Specialties", value: vm.specialties)
                    if !vm.userEmail.isEmpty {
                        profileDetailRow("Email", value: vm.userEmail)
                    }
                }

                Section {
                    Button {
                        appState.presentOnboarding(mode: .editProfile)
                    } label: {
                        Label("Refresh Verified RIA Profile", systemImage: "arrow.clockwise.circle.fill")
                    }
                }
            } else {
                // Account email for incomplete profiles
                Section("Account") {
                    if let email = appState.authenticatedIdentityEmail ?? (vm.userEmail.isEmpty ? nil : vm.userEmail) {
                        profileDetailRow("Email", value: email)
                    }
                    profileDetailRow("Profile Status", value: "Verified profile incomplete")
                }
            }

            // Legal
            Section("Legal") {
                Button {
                    showPrivacySheet = true
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                        .foregroundStyle(.primary)
                }

                Button {
                    showTermsSheet = true
                } label: {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                        .foregroundStyle(.primary)
                }

                HStack {
                    Label("App Version", systemImage: "info.circle.fill")
                    Spacer()
                    Text(vm.appVersion)
                        .foregroundStyle(.secondary)
                }
            }

            // Account actions
            Section {
                if appState.isInternalAdminSession {
                    HStack {
                        Text("Access")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Internal Test Access")
                    }
                }

                Button(role: .destructive) {
                    Task {
                        await vm.signOut(appState: appState)
                    }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }

                if !appState.isInternalAdminSession {
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
                            Label("Delete Account", systemImage: "trash.fill")
                        }
                    }
                    .disabled(vm.isDeleting)
                }
            } footer: {
                Text(accountFooterText)
            }
        }
        .sheet(isPresented: $showPrivacySheet) {
            LegalSheetView(
                title: "Privacy Policy",
                icon: "hand.raised.fill",
                content: """
                Last updated: March 2026

                Hushh Agents ("the App") is operated by Hushh.ai. We take your privacy seriously.

                Information We Collect
                • Public profile details and images we retrieve from public records and firm websites during RIA profile lookup
                • Name, email, and phone number you provide in the app
                • Swipe activity (saved and passed agents)
                • Messages sent through in-app chat

                How We Use Your Data
                • To display your RIA profile to other users
                • To match you with relevant agents
                • To enable in-app messaging

                Storage & Security
                All data is stored securely on Supabase infrastructure with row-level security policies. Your data is never sold to third parties.

                Your Rights
                You can delete all your data at any time using the "Delete Account" option in your Profile. This permanently removes your profile, retrieved public-profile data, swipes, and conversations.

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
                • Do not provide misleading identity details or misuse profile lookup results
                • Do not use the app for spam or solicitation

                Content Ownership
                You retain ownership of the content you provide in the app. By sharing it, you grant Hushh.ai a license to display it within the app.

                Disclaimers
                The app is provided "as is." We do not guarantee the accuracy of public-record matches, third-party sources, or user-submitted credentials.

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

    // MARK: - Header Row

    private var headerRow: some View {
        VStack(spacing: 10) {
            AsyncImage(url: vm.avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Text(vm.avatarInitials)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .id(vm.avatarURLString ?? vm.avatarInitials)

            VStack(spacing: 3) {
                Text(vm.userName)
                    .font(.title3.bold())

                if !vm.businessName.isEmpty {
                    Text(vm.businessName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !vm.visibilityLabel.isEmpty {
                    Text(vm.visibilityLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(vm.visibilityLabel == "Discoverable" ? .green : .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var incompleteHeaderRow: some View {
        VStack(spacing: 10) {
            AsyncImage(url: appState.authenticatedIdentityAvatarURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Text(appState.authenticatedIdentityInitials)
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            VStack(spacing: 3) {
                Text(appState.authenticatedIdentityName)
                    .font(.title3.bold())

                if let email = appState.authenticatedIdentityEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Verified profile incomplete")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func profileDetailRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }

    private func statItem(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var hasRecordedActivity: Bool {
        vm.selectedAgentsCount > 0 || vm.passedAgentsCount > 0 || vm.chatsCount > 0
    }

    private var accountFooterText: String {
        if appState.isInternalAdminSession {
            return "Internal test access uses a shared account. Deleting is disabled to protect shared data."
        }
        return "Deleting your account permanently removes your profile, swipes, conversations, and all associated data."
    }

    // MARK: - Guest State

    private var guestState: some View {
        Form {
            Section {
                Label {
                    Text("Build your verified profile")
                        .font(.headline)
                } icon: {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }

                Text("Sign in to turn guest browsing into a real Hushh Agents account. We'll sync your deck activity and guide you through publishing your verified advisor profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    appState.triggerGatedAction(.openProfile)
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign In")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileHomeView()
        .environmentObject(AppState())
}
