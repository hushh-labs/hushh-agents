import Foundation

/// Persistent store for liked agents using UserDefaults.
final class LikedAgentsStore: ObservableObject {
    static let shared = LikedAgentsStore()

    private let key = "liked_agents_v1"

    @Published var likedAgents: [KirklandAgent] = []

    private init() {
        loadFromDisk()
    }

    func addAgent(_ agent: KirklandAgent) {
        guard !likedAgents.contains(where: { $0.id == agent.id }) else { return }
        likedAgents.insert(agent, at: 0)
        saveToDisk()
    }

    func removeAgent(_ agent: KirklandAgent) {
        likedAgents.removeAll { $0.id == agent.id }
        saveToDisk()
    }

    func isLiked(_ agent: KirklandAgent) -> Bool {
        likedAgents.contains { $0.id == agent.id }
    }

    func agentIds() -> Set<String> {
        Set(likedAgents.map(\.id))
    }

    // MARK: - Persistence

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(likedAgents)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("[LikedAgentsStore] Save failed: \(error)")
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        do {
            likedAgents = try JSONDecoder().decode([KirklandAgent].self, from: data)
        } catch {
            print("[LikedAgentsStore] Load failed: \(error)")
        }
    }
}
