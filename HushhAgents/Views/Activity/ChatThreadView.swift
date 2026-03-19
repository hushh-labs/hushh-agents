import SwiftUI

struct ChatThreadView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ChatThreadViewModel()
    let agent: KirklandAgent

    var body: some View {
        Group {
            if let userId = appState.authenticatedUserId {
                conversationBody(userId: userId)
            } else {
                ContentUnavailableView(
                    "Sign in required",
                    systemImage: "lock.fill",
                    description: Text("Conversations are tied to your RIA account.")
                )
            }
        }
        .navigationTitle(agent.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    if let phone = agent.phone, !phone.isEmpty,
                       let url = URL(string: "tel://\(phone)") {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(Color.hushhPrimary)
                        }
                    }
                    if let website = agent.websiteURL {
                        Link(destination: website) {
                            Image(systemName: "globe")
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(Color.hushhPrimary)
                        }
                    }
                }
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task(id: appState.authenticatedUserId) {
            if let userId = appState.authenticatedUserId {
                await vm.load(userId: userId, agent: agent)
            }
        }
    }

    // MARK: - Conversation Body

    private func conversationBody(userId: UUID) -> some View {
        VStack(spacing: 0) {
            // Error banner
            if let loadError = vm.loadError {
                VStack(spacing: 8) {
                    Text("Failed to load conversation")
                        .font(.subheadline.weight(.semibold))
                    Text(loadError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await vm.load(userId: userId, agent: agent) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.hushhPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.08))
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        // Loading indicator
                        if vm.isLoading {
                            ProgressView("Setting up conversation…")
                                .padding(.vertical, 40)
                        }

                        // Welcome header
                        if vm.messages.isEmpty && !vm.isLoading && vm.loadError == nil {
                            chatEmptyHeader
                        }

                        ForEach(vm.messages) { message in
                            ChatBubble(message: message, agentName: agent.name)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: vm.messages.count) {
                    if let lastId = vm.messages.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            // Send error
            if let sendError = vm.sendError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(sendError)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Dismiss") { vm.sendError = nil }
                        .font(.caption.bold())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.06))
            }

            // Composer (disabled when conversation not ready)
            chatComposer(userId: userId)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Empty Header

    private var chatEmptyHeader: some View {
        VStack(spacing: 10) {
            AsyncImage(url: agent.primaryPhotoURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Color.hushhPrimary.opacity(0.12))
                        .overlay(
                            Text(String(agent.name.prefix(2)).uppercased())
                                .font(.title3.bold())
                                .foregroundStyle(Color.hushhPrimary)
                        )
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            Text(agent.name)
                .font(.headline)

            Text("Start a conversation or take notes about this RIA.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
    }

    // MARK: - Composer

    private func chatComposer(userId: UUID) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message…", text: $vm.draftMessage, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )

            Button {
                Task { await vm.send(userId: userId) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 34))
                    .foregroundStyle(
                        vm.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(.tertiaryLabel)
                            : Color.hushhPrimary
                    )
            }
            .disabled(vm.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(.bar)
                .shadow(color: .black.opacity(0.04), radius: 1, y: -1)
        )
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: HushhAgentMessage
    let agentName: String

    private var isOwner: Bool { message.senderRole == "owner" }
    private var isSystem: Bool { message.senderRole == "system" }

    var body: some View {
        if isSystem {
            systemBubble
        } else {
            messageBubble
        }
    }

    // MARK: - System Bubble (centered)

    private var systemBubble: some View {
        HStack {
            Spacer()
            Text(message.body)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                )
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Message Bubble (left/right)

    private var messageBubble: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isOwner { Spacer(minLength: 60) }

            VStack(alignment: isOwner ? .trailing : .leading, spacing: 2) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(isOwner ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isOwner
                            ? Color.hushhPrimary
                            : Color(.secondarySystemGroupedBackground)
                    )
                    .clipShape(ChatBubbleShape(isOwner: isOwner))

                Text(formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }

            if !isOwner { Spacer(minLength: 60) }
        }
        .padding(.vertical, 2)
    }

    private var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: message.createdAt) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date2 = formatter.date(from: message.createdAt) else {
                return ""
            }
            return timeString(from: date2)
        }
        return timeString(from: date)
    }

    private func timeString(from date: Date) -> String {
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        return tf.string(from: date)
    }
}

// MARK: - Chat Bubble Shape

private struct ChatBubbleShape: Shape {
    let isOwner: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6

        if isOwner {
            // Owner bubble - rounded with bottom-right tail
            var path = Path()
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius),
                style: .continuous
            )
            // Small tail at bottom right
            path.move(to: CGPoint(x: rect.width - tailSize, y: rect.height - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height),
                control: CGPoint(x: rect.width - tailSize, y: rect.height)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.width - tailSize - 4, y: rect.height),
                control: CGPoint(x: rect.width - tailSize, y: rect.height)
            )
            return path
        } else {
            // Other bubble - rounded with bottom-left tail
            var path = Path()
            path.addRoundedRect(
                in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius),
                style: .continuous
            )
            // Small tail at bottom left
            path.move(to: CGPoint(x: tailSize, y: rect.height - radius))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height),
                control: CGPoint(x: tailSize, y: rect.height)
            )
            path.addQuadCurve(
                to: CGPoint(x: tailSize + 4, y: rect.height),
                control: CGPoint(x: tailSize, y: rect.height)
            )
            return path
        }
    }
}

#Preview {
    NavigationStack {
        ChatThreadView(agent: PreviewData.sampleAgent)
            .environmentObject(AppState())
    }
}
