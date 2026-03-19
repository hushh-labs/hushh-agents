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
            Picker("Activity", selection: $appState.activitySection) {
                ForEach(ActivitySection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if vm.isLoading {
                ProgressView("Loading activity…")
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
        VStack(spacing: 18) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 54))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.hushhPrimary)

            Text("Sign in to save RIAs, revisit passed profiles, and keep your outreach threads in one place.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Sign In") {
                appState.showAuthSheet = true
            }
            .font(.headline.weight(.semibold))
            .buttonStyle(.borderedProminent)
            .tint(Color.hushhPrimary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Saved

    private func savedList(userId: UUID) -> some View {
        List {
            if vm.savedAgents.isEmpty {
                emptyRow(
                    title: "No saved RIAs yet",
                    systemName: "heart.slash.fill",
                    message: "Swipe right on the deck and they'll appear here instantly."
                )
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
                emptyRow(
                    title: "No passed RIAs",
                    systemName: "arrow.uturn.backward.circle.fill",
                    message: "Every left swipe you make stays editable and will show up here."
                )
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
                emptyRow(
                    title: "No conversations yet",
                    systemName: "bubble.left.and.bubble.right.fill",
                    message: "Saving an RIA creates a conversation thread for notes and outreach."
                )
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
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty Row

    @ViewBuilder
    private func emptyRow(title: String, systemName: String, message: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemName,
            description: Text(message)
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
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
            // Agent info
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

            // Action buttons
            HStack(spacing: 8) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.action) {
                        Label {
                            Text(action.title)
                        } icon: {
                            Image(systemName: action.icon)
                                .symbolRenderingMode(.monochrome)
                        }
                        .font(.subheadline.weight(.medium))
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
        .padding(.vertical, 6)
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

#Preview {
    ActivityHubView()
        .environmentObject(AppState())
}
