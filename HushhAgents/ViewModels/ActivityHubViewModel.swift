import Foundation
import Supabase

@MainActor
final class ActivityHubViewModel: ObservableObject {
    struct ActivityAgentItem: Identifiable {
        let agent: KirklandAgent
        let status: String
        let swipedAt: String?

        var id: String { agent.deckTargetKey }
    }

    @Published var isLoading = false
    @Published var savedAgents: [ActivityAgentItem] = []
    @Published var passedAgents: [ActivityAgentItem] = []
    @Published var conversations: [HushhAgentConversation] = []

    private let agentService = AgentService()
    private let swipeService = SwipeService()
    private let chatService = ChatService()

    private var agentsById: [String: KirklandAgent] = [:]
    private var observedUserId: UUID?
    private var realtimeChannels: [RealtimeChannelV2] = []
    private var realtimeTask: Task<Void, Never>?

    deinit {
        let channels = realtimeChannels
        Task {
            for channel in channels {
                await SupabaseService.shared.client.removeChannel(channel)
            }
        }
        realtimeTask?.cancel()
    }

    func load(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        let agents = await agentService.fetchDeckAgents(prioritizingUserId: userId)
        agentsById = Dictionary(uniqueKeysWithValues: agents.map { ($0.deckTargetKey, $0) })

        async let swipesTask = swipeService.fetchRemoteSelections(userId: userId)
        async let conversationsTask = chatService.fetchConversations(ownerUserId: userId)

        let swipes = (try? await swipesTask) ?? []
        let conversations = (try? await conversationsTask) ?? []

        apply(swipes: swipes, conversations: conversations)
    }

    func observe(userId: UUID) {
        guard observedUserId != userId else { return }
        stopObserving()
        observedUserId = userId

        let swipeChannel = SupabaseService.shared.client.channel("ria-swipes-\(userId.uuidString)")
        let swipeStream = swipeChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "hushh_agents_agent_swipes",
            filter: .eq("actor_user_id", value: userId)
        )

        let conversationChannel = SupabaseService.shared.client.channel("ria-conversations-\(userId.uuidString)")
        let conversationStream = conversationChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "hushh_agents_conversations",
            filter: .eq("owner_user_id", value: userId)
        )

        let messageChannel = SupabaseService.shared.client.channel("ria-messages-\(userId.uuidString)")
        let messageStream = messageChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "hushh_agents_messages",
            filter: .eq("owner_user_id", value: userId)
        )

        realtimeChannels = [swipeChannel, conversationChannel, messageChannel]

        realtimeTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await swipeChannel.subscribeWithError()
                try await conversationChannel.subscribeWithError()
                try await messageChannel.subscribeWithError()
            } catch {
                print("[ActivityHubViewModel] Failed to subscribe to realtime: \(error.localizedDescription)")
                return
            }

            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    for await _ in swipeStream {
                        await self?.load(userId: userId)
                    }
                }

                group.addTask { [weak self] in
                    for await _ in conversationStream {
                        await self?.load(userId: userId)
                    }
                }

                group.addTask { [weak self] in
                    for await _ in messageStream {
                        await self?.load(userId: userId)
                    }
                }
            }
        }
    }

    func stopObserving() {
        observedUserId = nil
        let channels = realtimeChannels
        realtimeChannels = []
        realtimeTask?.cancel()
        realtimeTask = nil

        Task {
            for channel in channels {
                await SupabaseService.shared.client.removeChannel(channel)
            }
        }
    }

    func updateSwipe(userId: UUID, agent: KirklandAgent, status: String) async {
        let swipedAt = swipeService.applyOptimisticSwipe(userId: userId, agent: agent, status: status)
        applyOptimisticSwipe(agent: agent, status: status, swipedAt: swipedAt, userId: userId)

        do {
            _ = try await swipeService.upsertSwipe(
                userId: userId,
                agent: agent,
                status: status,
                swipedAt: swipedAt,
                postsChangeNotification: false
            )
            if status == "selected" {
                _ = try await chatService.ensureConversation(ownerUserId: userId, agent: agent)
            } else {
                _ = try await chatService.archiveConversation(ownerUserId: userId, agent: agent)
            }
            NotificationCenter.default.post(name: SwipeService.didChangeNotification, object: nil)
            await load(userId: userId)
        } catch {
            await load(userId: userId)
            print("[ActivityHubViewModel] Failed to update swipe: \(error.localizedDescription)")
        }
    }

    func agent(for conversation: HushhAgentConversation) -> KirklandAgent? {
        agentsById[conversation.deckTargetKey]
    }

    func agent(forAgentId agentId: String) -> KirklandAgent? {
        agentsById[agentId]
    }

    private func apply(swipes: [HushhAgentSwipe], conversations: [HushhAgentConversation]) {
        let latestSwipes = Dictionary(grouping: swipes, by: \.deckTargetKey).compactMap { _, groupedSwipes in
            groupedSwipes.max { lhs, rhs in
                sortKey(swipedAt: lhs.swipedAt, updatedAt: lhs.updatedAt, createdAt: lhs.createdAt)
                    < sortKey(swipedAt: rhs.swipedAt, updatedAt: rhs.updatedAt, createdAt: rhs.createdAt)
            }
        }

        let sortedSwipes = latestSwipes.sorted { lhs, rhs in
            sortKey(swipedAt: lhs.swipedAt, updatedAt: lhs.updatedAt, createdAt: lhs.createdAt)
                > sortKey(swipedAt: rhs.swipedAt, updatedAt: rhs.updatedAt, createdAt: rhs.createdAt)
        }

        savedAgents = sortedSwipes
            .filter { $0.status == "selected" }
            .compactMap { swipe in
                guard let agent = agentsById[swipe.deckTargetKey] else { return nil }
                return ActivityAgentItem(agent: agent, status: swipe.status, swipedAt: swipe.swipedAt)
            }

        passedAgents = sortedSwipes
            .filter { $0.status == "rejected" }
            .compactMap { swipe in
                guard let agent = agentsById[swipe.deckTargetKey] else { return nil }
                return ActivityAgentItem(agent: agent, status: swipe.status, swipedAt: swipe.swipedAt)
            }

        self.conversations = conversations
            .filter { $0.status == "active" }
            .sorted { lhs, rhs in
                sortKey(swipedAt: lhs.lastMessageAt, updatedAt: lhs.updatedAt, createdAt: lhs.createdAt)
                    > sortKey(swipedAt: rhs.lastMessageAt, updatedAt: rhs.updatedAt, createdAt: rhs.createdAt)
            }
    }

    private func applyOptimisticSwipe(agent: KirklandAgent, status: String, swipedAt: String, userId: UUID) {
        let item = ActivityAgentItem(agent: agent, status: status, swipedAt: swipedAt)

        savedAgents.removeAll { $0.agent.deckTargetKey == agent.deckTargetKey }
        passedAgents.removeAll { $0.agent.deckTargetKey == agent.deckTargetKey }

        if status == "selected" {
            savedAgents.insert(item, at: 0)
            upsertOptimisticConversation(for: agent, userId: userId)
        } else {
            passedAgents.insert(item, at: 0)
            conversations.removeAll { $0.deckTargetKey == agent.deckTargetKey }
        }
    }

    private func upsertOptimisticConversation(for agent: KirklandAgent, userId: UUID) {
        let existingConversation = conversations.first(where: { $0.deckTargetKey == agent.deckTargetKey })
        let conversation = HushhAgentConversation(
            id: existingConversation?.id ?? UUID(),
            ownerUserId: userId,
            targetKind: agent.targetKind,
            targetAgentId: agent.targetKind == .catalog ? agent.resolvedCatalogAgentId : nil,
            targetProfileUserId: agent.targetKind == .profile ? agent.targetProfileUserId : nil,
            targetAgentName: agent.name,
            targetAgentLocation: [agent.city, agent.state].compactMap { $0 }.joined(separator: ", "),
            targetAgentPhotoURL: agent.primaryPhotoURL?.absoluteString,
            status: "active",
            lastMessagePreview: existingConversation?.lastMessagePreview,
            lastMessageAt: existingConversation?.lastMessageAt,
            createdAt: existingConversation?.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        conversations.removeAll { $0.deckTargetKey == agent.deckTargetKey }
        conversations.insert(conversation, at: 0)
    }

    private func sortKey(swipedAt: String?, updatedAt: String?, createdAt: String?) -> String {
        swipedAt ?? updatedAt ?? createdAt ?? ""
    }
}
