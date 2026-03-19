import SwiftUI

// MARK: - Auth Gate View Modifier
struct AuthGateModifier: ViewModifier {
    @Binding var isAuthenticated: Bool
    @State private var showAuthSheet = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !isAuthenticated {
                    showAuthSheet = true
                }
            }
            .onChange(of: isAuthenticated) { _, newValue in
                if !newValue {
                    showAuthSheet = true
                }
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthView()
                    .interactiveDismissDisabled(false)
            }
    }
}

// MARK: - View Extension
extension View {
    func authGate(isAuthenticated: Binding<Bool>) -> some View {
        modifier(AuthGateModifier(isAuthenticated: isAuthenticated))
    }
}
