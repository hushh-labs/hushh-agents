import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: tabSelection) {
            DeckView()
                .environmentObject(appState)
                .tag(AppTab.deck)
                .tabItem {
                    Label("Deck", systemImage: "square.stack.3d.up.fill")
                }

            ActivityHubView()
                .environmentObject(appState)
                .tag(AppTab.activity)
                .tabItem {
                    Label("Activity", systemImage: "bubble.left.and.bubble.right.fill")
                }

            ProfileHomeView()
                .environmentObject(appState)
                .tag(AppTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .symbolRenderingMode(.monochrome)
        .sheet(isPresented: $appState.showAuthSheet, onDismiss: {
            appState.handleAuthSheetDismissal()
        }) {
            AuthView()
                .environmentObject(appState)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .fullScreenCover(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
        .tint(Color.hushhPrimary)
    }

    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { appState.selectedTab },
            set: { newValue in
                guard !appState.isGuestBrowsingMode || newValue == .deck else {
                    appState.selectedTab = newValue

                    switch newValue {
                    case .activity:
                        appState.triggerGatedAction(.openActivity(section: appState.activitySection))
                    case .profile:
                        appState.triggerGatedAction(.openProfile)
                    case .deck:
                        break
                    }

                    return
                }

                appState.selectedTab = newValue
            }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
