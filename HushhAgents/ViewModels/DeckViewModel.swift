import Foundation

@MainActor
final class DeckViewModel: ObservableObject {
    @Published var cards: [KirklandAgent] = []
    @Published var currentIndex: Int = 0
    @Published var selectedAgent: KirklandAgent? = nil
    @Published var isLoading: Bool = true
    @Published var swipeStatuses: [String: String] = [:]

    private var allAgents: [KirklandAgent] = []
    private var currentUserId: UUID? = nil

    private let agentService = AgentService()
    private let swipeService = SwipeService()
    private let chatService = ChatService()

    var topCards: [KirklandAgent] {
        guard !cards.isEmpty else { return [] }
        let endIndex = min(currentIndex + 3, cards.count)
        guard currentIndex < endIndex else { return [] }
        return Array(cards[currentIndex..<endIndex])
    }

    func loadAgents(userId: UUID? = nil) async {
        isLoading = true
        currentUserId = userId

        allAgents = await agentService.fetchDeckAgents(prioritizingUserId: userId)

        if let userId, let selections = try? await swipeService.fetchRemoteSelections(userId: userId) {
            swipeStatuses = Dictionary(uniqueKeysWithValues: selections.map { ($0.deckTargetKey, $0.status) })
        } else {
            swipeStatuses = [:]
        }

        // Show unswiped agents first, then swiped agents at the end
        let swipedIds = Set(swipeStatuses.keys)
        let unswiped = allAgents.filter { !swipedIds.contains($0.deckTargetKey) }
        let swiped = allAgents.filter { swipedIds.contains($0.deckTargetKey) }
        cards = unswiped + swiped

        currentIndex = 0
        isLoading = false
    }

    private func reshuffleDeck() {
        let swipedIds = Set(swipeStatuses.keys)
        let unswiped = allAgents.filter { !swipedIds.contains($0.deckTargetKey) }
        let swiped = allAgents.filter { swipedIds.contains($0.deckTargetKey) }
        cards = unswiped + swiped
        currentIndex = 0
    }

    func status(for agent: KirklandAgent) -> String? {
        swipeStatuses[agent.deckTargetKey]
    }

    func saveTopAgent() {
        guard let topAgent = topCards.first else { return }
        swipe(topAgent, direction: .interested)
    }

    func swipe(_ agent: KirklandAgent, direction: SwipeDirection) {
        let status: String
        switch direction {
        case .pass:
            status = "rejected"
        case .interested:
            status = "selected"
        }

        swipeStatuses[agent.deckTargetKey] = status
        cards.removeAll { $0.deckTargetKey == agent.deckTargetKey }

        if let userId = currentUserId {
            let swipedAt = swipeService.applyOptimisticSwipe(userId: userId, agent: agent, status: status)
            Task {
                do {
                    _ = try await swipeService.upsertSwipe(
                        userId: userId,
                        agent: agent,
                        status: status,
                        swipedAt: swipedAt,
                        postsChangeNotification: false
                    )
                } catch {
                    print("[DeckViewModel] Failed to upsert swipe for \(agent.deckTargetKey): \(error.localizedDescription)")
                }

                do {
                    if status == "selected" {
                        _ = try await chatService.ensureConversation(ownerUserId: userId, agent: agent)
                    } else {
                        _ = try await chatService.archiveConversation(ownerUserId: userId, agent: agent)
                    }
                } catch {
                    print("[DeckViewModel] Failed to manage conversation for \(agent.deckTargetKey): \(error.localizedDescription)")
                }

                NotificationCenter.default.post(name: SwipeService.didChangeNotification, object: nil)
            }
        } else {
            swipeService.queueGuestSwipe(agent: agent, status: status)
        }

        if currentIndex >= cards.count {
            currentIndex = max(0, cards.count - 1)
        }

        if cards.isEmpty {
            reshuffleDeck()
        }
    }
}
