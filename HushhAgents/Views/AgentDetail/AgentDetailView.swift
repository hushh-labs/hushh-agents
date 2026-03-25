import SwiftUI
import MapKit

struct AgentDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var swipeStatus: String?

    let agent: KirklandAgent

    private var statusLabel: (title: String, icon: String, tint: Color)? {
        switch swipeStatus {
        case "selected":
            return ("Saved", "heart.fill", .green)
        case "rejected":
            return ("Passed", "xmark.circle.fill", .red)
        default:
            return nil
        }
    }

    private var conversationButtonTitle: String {
        appState.isGuestBrowsingMode ? "Sign In to Start Conversation" : "Open Conversation"
    }

    var body: some View {
        NavigationStack {
            List {
                // Hero photo
                Section {
                    AsyncImage(url: agent.primaryPhotoURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .overlay(
                                    Image(systemName: "person.crop.rectangle")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .listRowInsets(EdgeInsets())
                }

                // Name & status
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(agent.name)
                            .font(.title2.bold())

                        if let statusLabel {
                            Label(statusLabel.title, systemImage: statusLabel.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(statusLabel.tint)
                        }

                        RatingStarsView(
                            rating: agent.avgRating ?? 0,
                            reviewCount: agent.reviewCount
                        )
                    }
                    .padding(.vertical, 4)
                }

                // Categories
                if !agent.categories.isEmpty {
                    Section("Categories") {
                        FlowLayout(spacing: 8) {
                            ForEach(agent.categories, id: \.self) { category in
                                CategoryBadge(category: category)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Contact
                Section("Contact") {
                    if let phone = agent.localizedPhone, !phone.isEmpty {
                        Label(phone, systemImage: "phone.fill")
                    }

                    if let website = agent.website, !website.isEmpty {
                        if let url = URL(string: website) {
                            Link(destination: url) {
                                Label {
                                    Text(website)
                                        .lineLimit(1)
                                } icon: {
                                    Image(systemName: "globe")
                                }
                            }
                        }
                    }

                    if let address = formattedShortAddress {
                        Label(address, systemImage: "mappin.and.ellipse")
                    }
                }

                // About
                if let bio = agent.bio, !bio.isEmpty {
                    Section("About") {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Services
                if !agent.services.isEmpty {
                    Section("Services") {
                        ForEach(agent.services, id: \.self) { service in
                            Label(service, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                        }
                    }
                }

                // Map
                if let lat = agent.latitude, let lng = agent.longitude {
                    Section("Location") {
                        mapSection(latitude: lat, longitude: lng)
                            .listRowInsets(EdgeInsets())
                    }
                }

                // Conversation button
                Section {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            appState.triggerGatedAction(.openConversation(agentId: agent.deckTargetKey))
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if appState.isGuestBrowsingMode {
                                Image(systemName: "lock.fill")
                                    .font(.subheadline)
                            }
                            Text(conversationButtonTitle)
                                .font(.body.weight(.semibold))
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(agent.name)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: "\(appState.authenticatedUserId?.uuidString ?? "guest")::\(agent.deckTargetKey)") {
                await loadSwipeStatus()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Helpers

    private var formattedShortAddress: String? {
        let parts = [agent.address1, agent.city, agent.state, agent.zip].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    private func loadSwipeStatus() async {
        guard let userId = appState.authenticatedUserId else {
            swipeStatus = nil
            return
        }

        let swipes = try? await SwipeService().fetchRemoteSelections(userId: userId)
        swipeStatus = swipes?.first(where: { $0.deckTargetKey == agent.deckTargetKey })?.status
    }

    @ViewBuilder
    private func mapSection(latitude: Double, longitude: Double) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        Map(initialPosition: .region(region)) {
            Marker(agent.name, coordinate: coordinate)
        }
        .frame(height: 200)
    }
}

#Preview {
    AgentDetailView(agent: PreviewData.sampleAgent)
        .environmentObject(AppState())
}
