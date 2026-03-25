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
            .background(Color(.systemGroupedBackground))
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
            }
        }
    }

    // MARK: - Authenticated Content

    @ViewBuilder
    private func content(for userId: UUID) -> some View {
        VStack(spacing: 0) {
            Picker("Activity", selection: $appState.activitySection) {
                ForEach(ActivitySection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if appState.needsVerifiedProfileCompletion {
                VerifiedProfileCompletionCard(
                    title: "Complete your verified profile",
                    message: "Finish setup before your advisor identity is fully reflected.",
                    buttonTitle: "Resume Lookup",
                    style: .compact
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            if vm.isLoading {
                ContentUnavailableView {
                    Label("Loading", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Preparing your activity…")
                }
                .frame(maxHeight: .infinity)
            } else {
                switch appState.activitySection {
                case .saved:  savedList(userId: userId)
                case .passed: passedList(userId: userId)
                case .chats:  chatsList
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
        Form {
            Section {
                Label {
                    Text("Activity syncs after sign in")
                        .font(.headline)
                } icon: {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }

                Text("Browse the deck as a guest. When you sign in, your saved and passed history syncs here and your outreach threads start from the same account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    appState.triggerGatedAction(.openActivity(section: appState.activitySection))
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

    // MARK: - Saved

    private func savedList(userId: UUID) -> some View {
        List {
            if vm.savedAgents.isEmpty {
                ContentUnavailableView(
                    appState.needsVerifiedProfileCompletion ? "Complete your profile" : "No saved RIAs yet",
                    systemImage: appState.needsVerifiedProfileCompletion ? "person.crop.circle.badge.exclamationmark" : "heart.slash.fill",
                    description: Text(appState.needsVerifiedProfileCompletion
                        ? "Finish setup so your saved network is tied to your real identity."
                        : "Swipe right on the deck and they'll appear here.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Passed

    private func passedList(userId: UUID) -> some View {
        List {
            if vm.passedAgents.isEmpty {
                ContentUnavailableView(
                    appState.needsVerifiedProfileCompletion ? "Complete your profile" : "No passed RIAs",
                    systemImage: appState.needsVerifiedProfileCompletion ? "person.crop.circle.badge.exclamationmark" : "arrow.uturn.backward.circle.fill",
                    description: Text(appState.needsVerifiedProfileCompletion
                        ? "Finish setup before you build more review history."
                        : "Every left swipe stays editable and will show up here.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Chats

    private var chatsList: some View {
        List {
            if vm.conversations.isEmpty {
                ContentUnavailableView(
                    appState.needsVerifiedProfileCompletion ? "Complete your profile" : "No conversations yet",
                    systemImage: appState.needsVerifiedProfileCompletion ? "person.crop.circle.badge.exclamationmark" : "bubble.left.and.bubble.right.fill",
                    description: Text(appState.needsVerifiedProfileCompletion
                        ? "Finish setup before starting outreach threads."
                        : "Saving an RIA creates a conversation thread for notes and outreach.")
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                                        .fill(Color(.systemGray5))
                                        .overlay(
                                            Text(String(conversation.targetAgentName.prefix(2)).uppercased())
                                                .font(.caption.bold())
                                                .foregroundStyle(.secondary)
                                        )
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(conversation.targetAgentName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)

                                Text(conversation.lastMessagePreview ?? "Open thread to start notes.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.quaternary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func openRequestedConversationIfPossible() {
        guard let requestedId = appState.requestedConversationAgentId else { return }
        if let agent = vm.agent(forAgentId: requestedId) {
            _ = appState.consumeRequestedConversationAgentId()
            selectedChatAgentId = agent.deckTargetKey
        } else if !vm.isLoading {
            _ = appState.consumeRequestedConversationAgentId()
        }
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
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.secondary)
                            )
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    Text([agent.city, agent.state].compactMap { $0 }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            HStack(spacing: 8) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.action) {
                        Label(action.title, systemImage: action.icon)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(foregroundColor(for: action.style))
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(backgroundColor(for: action.style))
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func foregroundColor(for style: RowAction.ActionStyle) -> Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .blue
        case .destructive: return .secondary
        }
    }

    private func backgroundColor(for style: RowAction.ActionStyle) -> Color {
        switch style {
        case .primary:     return .accentColor
        case .secondary:   return Color(.tertiarySystemFill)
        case .destructive: return Color(.tertiarySystemFill)
        }
    }
}

#Preview {
    ActivityHubView()
        .environmentObject(AppState())
}
