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
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if appState.needsVerifiedProfileCompletion {
                    incompleteProfileContent
                } else {
                    completeProfileContent
                }

                legalSectionCard
                accountSectionCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(profileBackground.ignoresSafeArea())
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

    private var profileBackground: some View {
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
                .offset(x: 170, y: -260)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 240, height: 240)
                .blur(radius: 20)
                .offset(x: -150, y: -150)
        }
    }

    private var incompleteProfileContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProfileSectionCard {
                incompleteAccountHeaderRow
            }

            VerifiedProfileCompletionCard(
                title: "Complete your verified profile",
                message: "You’re signed in, but your advisor identity is still unfinished. Resume the lookup you skipped so Hushh reflects the right public profile instead of placeholders.",
                buttonTitle: "Resume Lookup"
            )

            if hasRecordedActivity {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("Activity")
                    statsRow
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Account")
                ProfileSectionCard {
                    VStack(spacing: 0) {
                        if let accountEmail = appState.authenticatedIdentityEmail ?? (vm.userEmail.isEmpty ? nil : vm.userEmail) {
                            profileRow(label: "Email", value: accountEmail)
                            divider
                        }
                        profileRow(label: "Profile Status", value: "Verified profile incomplete")
                    }
                }
            }
        }
    }

    private var completeProfileContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            ProfileSectionCard {
                headerRow
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Activity")
                statsRow
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Profile")
                ProfileSectionCard {
                    VStack(spacing: 0) {
                        profileRow(label: "Categories", value: vm.categoriesLine)
                        divider
                        profileRow(label: "Location", value: vm.location)
                        divider
                        profileRow(label: "Specialties", value: vm.specialties)
                        if !vm.userEmail.isEmpty {
                            divider
                            profileRow(label: "Email", value: vm.userEmail)
                        }
                    }
                }
            }

            ProfileSectionCard {
                Button {
                    appState.presentOnboarding(mode: .editProfile)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Refresh Verified RIA Profile")
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.hushhPrimary,
                                Color.hushhPrimary.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var legalSectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Legal")

            ProfileSectionCard {
                VStack(spacing: 0) {
                    settingsRow(
                        title: "Privacy Policy",
                        systemImage: "hand.raised.fill"
                    ) {
                        showPrivacySheet = true
                    }

                    divider

                    settingsRow(
                        title: "Terms of Service",
                        systemImage: "doc.text.fill"
                    ) {
                        showTermsSheet = true
                    }

                    divider

                    HStack {
                        Label("App Version", systemImage: "info.circle.fill")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(vm.appVersion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 14)
                }
            }
        }
    }

    private var accountSectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Account")

            ProfileSectionCard {
                VStack(spacing: 0) {
                    destructiveRow(
                        title: "Sign Out",
                        systemImage: "rectangle.portrait.and.arrow.right"
                    ) {
                        Task {
                            await vm.signOut(appState: appState)
                        }
                    }

                    divider

                    destructiveRow(
                        title: vm.isDeleting ? "Deleting…" : "Delete Account",
                        systemImage: "trash.fill",
                        showsProgress: vm.isDeleting
                    ) {
                        showDeleteConfirmation = true
                    }
                    .disabled(vm.isDeleting)
                }
            }

            Text("Deleting your account permanently removes your profile, swipes, conversations, and all associated data.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var hasRecordedActivity: Bool {
        vm.selectedAgentsCount > 0 || vm.passedAgentsCount > 0 || vm.chatsCount > 0
    }

    // MARK: - Header Row (Apple Settings style)

    private var headerRow: some View {
        VStack(spacing: 12) {
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
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )

            VStack(spacing: 4) {
                Text(vm.userName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                if !vm.businessName.isEmpty {
                    Text(vm.businessName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                if !vm.roleLine.isEmpty {
                    Text(vm.roleLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !vm.visibilityLabel.isEmpty {
                    Label(vm.visibilityLabel, systemImage: vm.visibilityLabel == "Discoverable" ? "eye.fill" : "eye.slash.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(vm.visibilityLabel == "Discoverable" ? Color.green : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill((vm.visibilityLabel == "Discoverable" ? Color.green : Color.secondary).opacity(0.1))
                        )
                        .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var incompleteAccountHeaderRow: some View {
        VStack(spacing: 12) {
            AsyncImage(url: appState.authenticatedIdentityAvatarURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Color.hushhPrimary.opacity(0.12))
                        .overlay(
                            Text(appState.authenticatedIdentityInitials)
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.hushhPrimary)
                        )
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )

            VStack(spacing: 6) {
                Text(appState.authenticatedIdentityName)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                if let email = appState.authenticatedIdentityEmail {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text("Signed in account")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Label("Verified profile incomplete", systemImage: "person.crop.circle.badge.exclamationmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.hushhPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.hushhPrimary.opacity(0.12))
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
    }

    // MARK: - Profile Row

    private func profileRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }

    // MARK: - Guest State

    private var guestState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 86, height: 86)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )

                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 40, weight: .regular))
                            .foregroundStyle(Color.hushhPrimary)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Build your verified profile")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))

                        Text("Sign in to turn guest browsing into a real Hushh Agents account. We’ll sync your deck activity, then guide you through publishing your verified advisor profile.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                GuestBrowsingCard(
                    title: "Your account starts here",
                    message: "Keep browsing freely for now. When you sign in, your deck history can follow you and your verified profile can power the rest of the app.",
                    buttonTitle: "Sign In"
                ) {
                    appState.triggerGatedAction(.openProfile)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(profileBackground.ignoresSafeArea())
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private var divider: some View {
        Divider()
            .overlay(Color.black.opacity(0.06))
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func destructiveRow(
        title: String,
        systemImage: String,
        showsProgress: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if showsProgress {
                    ProgressView()
                        .tint(.red)
                } else {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .font(.body.weight(.semibold))

                Spacer()
            }
            .foregroundStyle(.red)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StatCard

private struct ProfileSectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(20)
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
}

private struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}

#Preview {
    ProfileHomeView()
        .environmentObject(AppState())
}
