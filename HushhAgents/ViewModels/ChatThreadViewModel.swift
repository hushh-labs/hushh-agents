import Foundation
import Supabase

@MainActor
final class ChatThreadViewModel: ObservableObject {
    @Published var conversation: HushhAgentConversation?
    @Published var messages: [HushhAgentMessage] = []
    @Published var draftMessage: String = ""
    @Published var isLoading = false
    @Published var isSending = false
    @Published var loadError: String?
    @Published var sendError: String?

    private let chatService = ChatService()
    private var messageChannel: RealtimeChannelV2?
    private var messageTask: Task<Void, Never>?

    /// True when conversation is loaded and ready for messaging
    var isReady: Bool { conversation != nil && !isLoading }

    deinit {
        if let messageChannel {
            Task {
                await SupabaseService.shared.client.removeChannel(messageChannel)
            }
        }
        messageTask?.cancel()
    }

    func load(userId: UUID, agent: KirklandAgent) async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let conversation = try await chatService.ensureConversation(ownerUserId: userId, agent: agent)
            self.conversation = conversation
            messages = try await chatService.fetchMessages(conversationId: conversation.id)
            observeMessages(conversationId: conversation.id)
        } catch {
            loadError = error.localizedDescription
            print("[ChatThreadViewModel] Failed to load conversation: \(error)")
        }
    }

    func send(userId: UUID) async {
        guard let conversation else {
            sendError = "Conversation not ready. Please wait or go back and try again."
            return
        }
        guard !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isSending = true
        sendError = nil
        let body = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        draftMessage = ""

        do {
            _ = try await chatService.sendOwnerMessage(
                conversationId: conversation.id,
                ownerUserId: userId,
                body: body
            )
            messages = try await chatService.fetchMessages(conversationId: conversation.id)
        } catch {
            draftMessage = body
            sendError = error.localizedDescription
            print("[ChatThreadViewModel] Failed to send message: \(error)")
        }

        isSending = false
    }

    private func observeMessages(conversationId: UUID) {
        if let messageChannel {
            Task {
                await SupabaseService.shared.client.removeChannel(messageChannel)
            }
        }
        messageTask?.cancel()

        let channel = SupabaseService.shared.client.channel("ria-thread-\(conversationId.uuidString)")
        let stream = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "hushh_agents_messages",
            filter: .eq("conversation_id", value: conversationId.uuidString)
        )
        messageChannel = channel

        messageTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await channel.subscribeWithError()
            } catch {
                print("[ChatThreadViewModel] Failed to subscribe to messages: \(error)")
                return
            }
            for await _ in stream {
                guard let conversation = self.conversation else { continue }
                self.messages = (try? await self.chatService.fetchMessages(conversationId: conversation.id)) ?? self.messages
            }
        }
    }
}
