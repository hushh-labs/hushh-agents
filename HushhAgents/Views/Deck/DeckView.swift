import SwiftUI

struct DeckView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var deckVM = DeckViewModel()

    @State private var selectedAgent: KirklandAgent?
    @State private var showLocationPicker = false
    @State private var currentLocation = "Kirkland, WA 98034"

    private let hPad: CGFloat = 16

    private var deckReloadKey: String {
        [
            appState.authenticatedUserId?.uuidString ?? "guest",
            appState.onboardingStatus == .complete ? "complete" : "incomplete"
        ].joined(separator: "::")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Location bar
                Button {
                    Haptics.impact(.light)
                    showLocationPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)

                        Text(currentLocation)
                            .font(.subheadline)
                            .foregroundStyle(.primary)

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)

                        Spacer()
                    }
                    .padding(.horizontal, hPad)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)

                // Surface notices
                if appState.isGuestBrowsingMode {
                    DeckSurfaceNotice(
                        icon: "person.crop.circle.badge.plus",
                        message: "Browsing as guest — swipes stay on device.",
                        actionTitle: "Sign In"
                    ) {
                        appState.presentGuestSignIn()
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, 6)
                } else if appState.needsVerifiedProfileCompletion {
                    DeckSurfaceNotice(
                        icon: "person.crop.circle.badge.exclamationmark",
                        message: "Finish your profile to publish your identity.",
                        actionTitle: "Resume"
                    ) {
                        appState.resumeVerifiedProfileCompletion()
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, 6)
                }

                // Card Stack
                GeometryReader { geo in
                    if deckVM.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading your deck…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        CardStackView(
                            deckVM: deckVM,
                            availableHeight: geo.size.height
                        ) { agent in
                            selectedAgent = agent
                        }
                        .environmentObject(appState)
                    }
                }
                .padding(.horizontal, hPad)

                // Action Dock
                if !deckVM.isLoading && !deckVM.topCards.isEmpty {
                    SwipeActionButtons.SwipeActionDock {
                        SwipeActionButtons(deckVM: deckVM)
                            .environmentObject(appState)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Discover RIAs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        appState.triggerGatedAction(.openActivity(section: .saved))
                    } label: {
                        Image(systemName: "heart.text.square.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .task(id: deckReloadKey) {
            await deckVM.loadAgents(userId: appState.authenticatedUserId)
        }
        .sheet(item: $selectedAgent) { agent in
            AgentDetailView(agent: agent)
                .environmentObject(appState)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(currentLocation: $currentLocation)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Surface Notice

private struct DeckSurfaceNotice: View {
    let icon: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            Button(actionTitle, action: action)
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Location Picker

struct LocationPickerView: View {
    @Binding var currentLocation: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let mockLocations = [
        "Kirkland, WA 98034",
        "Kirkland, WA 98033",
        "Bellevue, WA 98004",
        "Bellevue, WA 98006",
        "Redmond, WA 98052",
        "Seattle, WA 98101",
        "Seattle, WA 98109",
        "Bothell, WA 98011",
        "Woodinville, WA 98072",
        "Renton, WA 98055",
    ]

    private var filteredLocations: [String] {
        if searchText.isEmpty { return mockLocations }
        return mockLocations.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Current Area") {
                    Button {
                        Haptics.impact(.light)
                        currentLocation = "Kirkland, WA 98034"
                        dismiss()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                }

                Section("Suggested Locations") {
                    ForEach(filteredLocations, id: \.self) { location in
                        Button {
                            Haptics.impact(.light)
                            currentLocation = location
                            dismiss()
                        } label: {
                            HStack {
                                Label(location, systemImage: "mappin.circle.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if location == currentLocation {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search by city or zip code")
            .navigationTitle("Change Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    DeckView()
        .environmentObject(AppState())
}
