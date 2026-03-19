import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
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
        .environment(\.symbolVariants, .fill)
        .sheet(isPresented: $appState.showAuthSheet) {
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
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
