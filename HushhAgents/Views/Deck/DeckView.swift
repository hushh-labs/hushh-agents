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
                // ── Header ──────────────────────────────────
                DeckHeaderView(currentLocation: currentLocation) {
                    Haptics.impact(.light)
                    showLocationPicker = true
                }
                .padding(.horizontal, hPad)
                .padding(.top, 2)
                .padding(.bottom, 8)

                // ── Card Stack (fills remaining space) ──────
                GeometryReader { geo in
                    if deckVM.isLoading {
                        loadingState
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

                // ── Action Dock (fixed at bottom) ───────────
                if !deckVM.isLoading && !deckVM.topCards.isEmpty {
                    SwipeActionDock {
                        SwipeActionButtons(deckVM: deckVM)
                            .environmentObject(appState)
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        appState.triggerGatedAction(.openActivity(section: .saved))
                    } label: {
                        Image(systemName: "heart.text.square.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.hushhPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                    }
                }
            }
        }
        .tint(Color.hushhPrimary)
        .task(id: deckReloadKey) {
            await deckVM.loadAgents(userId: appState.authenticatedUserId)
        }
        .sheet(item: $selectedAgent) { agent in
            AgentDetailView(agent: agent)
                .environmentObject(appState)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(currentLocation: $currentLocation)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.1)
                .tint(Color.hushhPrimary)
            Text("Loading your deck…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Header

private struct DeckHeaderView: View {
    let currentLocation: String
    let onLocationTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Discover RIAs")
                .font(.largeTitle.bold())

            Button(action: onLocationTap) {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.hushhPrimary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.hushhPrimary.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Current Area")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(currentLocation)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
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
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color.hushhPrimary)
                            Text("Use Current Location")
                                .foregroundStyle(Color.hushhPrimary)
                            Spacer()
                            Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                .foregroundStyle(Color.hushhPrimary)
                        }
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
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.secondary)
                                Text(location)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if location == currentLocation {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.hushhPrimary)
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
                ToolbarItem(placement: .navigationBarTrailing) {
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
