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
            return ("Saved", "heart.fill", .hushhLike)
        case "rejected":
            return ("Passed", "xmark.circle.fill", .hushhPass)
        default:
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: – Hero photo
                    AsyncImage(url: agent.primaryPhotoURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.crop.rectangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    // MARK: – Name & rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text(agent.name)
                            .font(.title.bold())

                        if let statusLabel {
                            Label(statusLabel.title, systemImage: statusLabel.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(statusLabel.tint)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(statusLabel.tint.opacity(0.12))
                                )
                        }

                        RatingStarsView(
                            rating: agent.avgRating ?? 0,
                            reviewCount: agent.reviewCount
                        )
                    }
                    .padding(.horizontal)

                    // MARK: – Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(agent.categories, id: \.self) { category in
                                CategoryBadge(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Divider().padding(.horizontal)

                    // MARK: – Contact info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Contact")
                            .font(.headline)

                        if let phone = agent.localizedPhone, !phone.isEmpty {
                            Label(phone, systemImage: "phone.fill")
                                .font(.subheadline)
                        }

                        if let website = agent.website, !website.isEmpty {
                            Label {
                                Text(website)
                                    .lineLimit(1)
                            } icon: {
                                Image(systemName: "globe")
                            }
                            .font(.subheadline)
                        }

                        if let address = formattedShortAddress {
                            Label(address, systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)

                    // MARK: – Bio
                    if let bio = agent.bio, !bio.isEmpty {
                        Divider().padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            Text(bio)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    // MARK: – Services
                    if !agent.services.isEmpty {
                        Divider().padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Services")
                                .font(.headline)

                            ForEach(agent.services, id: \.self) { service in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.hushhLike)
                                        .font(.subheadline)
                                    Text(service)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // MARK: – Map
                    if let lat = agent.latitude, let lng = agent.longitude {
                        Divider().padding(.horizontal)

                        mapSection(latitude: lat, longitude: lng)
                    }

                    // MARK: – Conversation button
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            appState.triggerGatedAction(.openConversation(agentId: agent.deckTargetKey))
                        }
                    } label: {
                        Text("Open Conversation")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.hushhPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
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

    // MARK: – Helpers

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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
    }
}

#Preview {
    AgentDetailView(agent: PreviewData.sampleAgent)
        .environmentObject(AppState())
}
