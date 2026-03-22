import SwiftUI
import UIKit

struct ActivityHubView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ActivityHubViewModel()
    @State private var selectedChatAgentId: String?
    @State private var selectedAgentDetail: KirklandAgent?

    var body: some View {
        NavigationStack {
            Group {
                if let userId = appState.authenticatedUserId {
                    content(for: userId)
                } else {
                    guestState
                }
            }
            .background(activityBackground.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedChatAgentId) { agentId in
                if let agent = vm.agent(forAgentId: agentId) {
                    ChatThreadView(agent: agent)
                        .environmentObject(appState)
                } else {
                    ContentUnavailableView(
                        "Agent Not Found",
                        systemImage: "exclamationmark.triangle.fill",
                        description: Text("This agent profile is no longer available.")
                    )
                }
            }
            .sheet(item: $selectedAgentDetail) { agent in
                AgentDetailView(agent: agent)
                    .environmentObject(appState)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(20)
            }
        }
    }

    // MARK: - Authenticated Content

    @ViewBuilder
    private func content(for userId: UUID) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Picker("Activity", selection: $appState.activitySection) {
                    ForEach(ActivitySection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .shadow(color: .black.opacity(0.04), radius: 14, y: 6)

            if appState.needsVerifiedProfileCompletion {
                VerifiedProfileCompletionCard(
                    title: "Complete your verified profile",
                    message: "Your account is active, but finish setup before your advisor identity is fully reflected across saved RIAs and conversations.",
                    buttonTitle: "Resume Lookup",
                    style: .compact
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            if vm.isLoading {
                ActivityEmptyStateCard(
                    systemName: "clock.arrow.circlepath",
                    title: "Loading activity",
                    message: "Saved RIAs, passes, and conversations are being prepared for this account."
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                switch appState.activitySection {
                case .saved:
                    savedList(userId: userId)
                case .passed:
                    passedList(userId: userId)
                case .chats:
                    chatsList
                }
            }
        }
        .task(id: userId) {
            await vm.load(userId: userId)
            vm.observe(userId: userId)
            openRequestedConversationIfPossible()
        }
        .onAppear {
            Task {
                await vm.load(userId: userId)
                openRequestedConversationIfPossible()
            }
        }
        .onChange(of: appState.requestedConversationAgentId) {
            openRequestedConversationIfPossible()
        }
        .onReceive(NotificationCenter.default.publisher(for: SwipeService.didChangeNotification)) { _ in
            Task {
                await vm.load(userId: userId)
                openRequestedConversationIfPossible()
            }
        }
    }

    // MARK: - Guest

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

                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 38, weight: .regular))
                            .foregroundStyle(Color.hushhPrimary)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Activity syncs after sign in")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))

                        Text("Browse the deck as a guest if you want. When you sign in, your saved and passed history can sync here and your outreach threads can start from the same account.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                GuestBrowsingCard(
                    title: "Keep your outreach history together",
                    message: "Sign in when you’re ready and your activity can follow you into saved lists, passed review, and conversations.",
                    buttonTitle: "Sign In"
                ) {
                    appState.triggerGatedAction(.openActivity(section: appState.activitySection))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Saved

    private func savedList(userId: UUID) -> some View {
        List {
            if vm.savedAgents.isEmpty {
                if appState.needsVerifiedProfileCompletion {
                    emptyRow(
                        title: "Complete your verified profile",
                        systemName: "person.crop.circle.badge.exclamationmark",
                        message: "Finish setup so your saved network is tied to your real advisor identity from the start."
                    )
                } else {
                    emptyRow(
                        title: "No saved RIAs yet",
                        systemName: "heart.slash.fill",
                        message: "Swipe right on the deck and they'll appear here instantly."
                    )
                }
            } else {
                ForEach(vm.savedAgents) { item in
                    AgentActivityRow(
                        agent: item.agent,
                        actions: [
                            .init(title: "Call", icon: "phone.fill", style: .secondary) {
                                if let phone = item.agent.phone, !phone.isEmpty,
                                   let url = URL(string: "tel://\(phone)") {
                                    UIApplication.shared.open(url)
                                }
                            },
                            .init(title: "Chat", icon: "message.fill", style: .primary) {
                                selectedChatAgentId = item.agent.deckTargetKey
                            },
                            .init(title: "Pass", icon: "xmark.circle.fill", style: .destructive) {
                                Task {
                                    await vm.updateSwipe(userId: userId, agent: item.agent, status: "rejected")
                                }
                            }
                        ]
                    ) {
                        selectedAgentDetail = item.agent
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Passed

    private func passedList(userId: UUID) -> some View {
        List {
            if vm.passedAgents.isEmpty {
                if appState.needsVerifiedProfileCompletion {
                    emptyRow(
                        title: "Complete your verified profile",
                        systemName: "person.crop.circle.badge.exclamationmark",
                        message: "Finish setup before you build more review history, so the rest of the app reflects the right profile."
                    )
                } else {
                    emptyRow(
                        title: "No passed RIAs",
                        systemName: "arrow.uturn.backward.circle.fill",
                        message: "Every left swipe you make stays editable and will show up here."
                    )
                }
            } else {
                ForEach(vm.passedAgents) { item in
                    AgentActivityRow(
                        agent: item.agent,
                        actions: [
                            .init(title: "Save", icon: "heart.fill", style: .primary) {
                                Task {
                                    await vm.updateSwipe(userId: userId, agent: item.agent, status: "selected")
                                }
                            },
                            .init(title: "Details", icon: "info.circle.fill", style: .secondary) {
                                selectedAgentDetail = item.agent
                            }
                        ]
                    ) {
                        selectedAgentDetail = item.agent
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Chats

    private var chatsList: some View {
        List {
            if vm.conversations.isEmpty {
                if appState.needsVerifiedProfileCompletion {
                    emptyRow(
                        title: "Complete your verified profile",
                        systemName: "person.crop.circle.badge.exclamationmark",
                        message: "Finish setup before you start building outreach threads, so your account has the right verified identity."
                    )
                } else {
                    emptyRow(
                        title: "No conversations yet",
                        systemName: "bubble.left.and.bubble.right.fill",
                        message: "Saving an RIA creates a conversation thread for notes and outreach."
                    )
                }
            } else {
                ForEach(vm.conversations) { conversation in
                    Button {
                        if let agent = vm.agent(for: conversation) {
                            selectedChatAgentId = agent.deckTargetKey
                        }
                    } label: {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: conversation.targetAgentPhotoURL ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    Circle()
                                        .fill(Color.hushhPrimary.opacity(0.12))
                                        .overlay(
                                            Text(String(conversation.targetAgentName.prefix(2)).uppercased())
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.hushhPrimary)
                                        )
                                }
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(conversation.targetAgentName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)

                                if !conversation.targetAgentLocation.isEmpty {
                                    Text(conversation.targetAgentLocation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(conversation.lastMessagePreview ?? "Open the thread to start your notes.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.quaternary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.regularMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.78), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Empty Row

    @ViewBuilder
    private func emptyRow(title: String, systemName: String, message: String) -> some View {
        ActivityEmptyStateCard(
            systemName: systemName,
            title: title,
            message: message
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    }

    private var activityBackground: some View {
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
                .offset(x: 180, y: -240)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 240, height: 240)
                .blur(radius: 22)
                .offset(x: -160, y: -140)
        }
    }

    private func openRequestedConversationIfPossible() {
        guard let requestedId = appState.requestedConversationAgentId else { return }
        // Only consume the ID once we can actually navigate to the agent
        if let agent = vm.agent(forAgentId: requestedId) {
            _ = appState.consumeRequestedConversationAgentId()
            selectedChatAgentId = agent.deckTargetKey
        } else if !vm.isLoading {
            // Agents have loaded but this agent wasn't found – consume to avoid infinite retry
            _ = appState.consumeRequestedConversationAgentId()
            print("[ActivityHubView] Requested conversation target \(requestedId) not found in deck")
        }
        // If still loading, don't consume – will be retried after load completes
    }
}

// MARK: - Agent Activity Row

private struct AgentActivityRow: View {
    let agent: KirklandAgent
    let actions: [RowAction]
    let onTap: () -> Void

    struct RowAction {
        let title: String
        let icon: String
        let style: ActionStyle
        let action: () -> Void

        enum ActionStyle { case primary, secondary, destructive }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                AsyncImage(url: agent.primaryPhotoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .symbolRenderingMode(.monochrome)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(agent.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)

                    Text([agent.city, agent.state].compactMap { $0 }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(agent.businessDetails.specialties)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            HStack(spacing: 8) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.action) {
                        Label {
                            Text(action.title)
                        } icon: {
                            Image(systemName: action.icon)
                                .symbolRenderingMode(.monochrome)
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(foregroundColor(for: action.style))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(backgroundColor(for: action.style))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }

    private func foregroundColor(for style: RowAction.ActionStyle) -> Color {
        switch style {
        case .primary:    return .white
        case .secondary:  return .hushhPrimary
        case .destructive: return .secondary
        }
    }

    private func backgroundColor(for style: RowAction.ActionStyle) -> Color {
        switch style {
        case .primary:    return .hushhPrimary
        case .secondary:  return Color.hushhPrimary.opacity(0.1)
        case .destructive: return Color(.tertiarySystemFill)
        }
    }
}

private struct ActivityEmptyStateCard: View {
    let systemName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.hushhPrimary.opacity(0.12))
                    .frame(width: 70, height: 70)

                Image(systemName: systemName)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.hushhPrimary)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
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

#Preview {
    ActivityHubView()
        .environmentObject(AppState())
}
