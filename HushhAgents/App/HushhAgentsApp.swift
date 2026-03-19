import SwiftUI
import GoogleSignIn

/// Main entry point for the Hushh Agents iOS app.
@main
struct HushhAgentsApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .onAppear {
                    Task {
                        await appState.checkSession()
                    }
                }
                .onOpenURL { url in
                    // Handle Google Sign-In callback URL
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
