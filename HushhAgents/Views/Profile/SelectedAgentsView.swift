import SwiftUI

struct SelectedAgentsView: View {
    @ObservedObject private var store = LikedAgentsStore.shared
    @State private var selectedAgent: KirklandAgent?

    var body: some View {
        Group {
            if store.likedAgents.isEmpty {
                ContentUnavailableView(
                    "No Saved Agents",
                    systemImage: "heart.slash.fill",
                    description: Text("Swipe right on agents you like.\nThey'll appear here.")
                )
            } else {
                List {
                    ForEach(store.likedAgents) { agent in
                        LikedAgentRow(agent: agent) {
                            selectedAgent = agent
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeAgent(store.likedAgents[index])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Saved Agents")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedAgent) { agent in
            AgentDetailView(agent: agent)
        }
    }
}

// MARK: - Liked Agent Row

struct LikedAgentRow: View {
    let agent: KirklandAgent
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Photo
                AsyncImage(url: agent.primaryPhotoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color(.systemGray5)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(agent.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let city = agent.city, let state = agent.state {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                                .symbolRenderingMode(.monochrome)
                            Text("\(city), \(state)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", agent.avgRating ?? 0))
                        Text("(\(agent.reviewCount))")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    // Call button
                    if let phone = agent.phone, !phone.isEmpty {
                        Button {
                            if let url = URL(string: "tel://\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Image(systemName: "phone.fill")
                                .font(.body)
                                .symbolRenderingMode(.monochrome)
                                .foregroundColor(.green)
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Chat button (mock)
                    Button {
                        onTap()
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.body)
                            .symbolRenderingMode(.monochrome)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

#Preview {
    NavigationStack {
        SelectedAgentsView()
    }
}
