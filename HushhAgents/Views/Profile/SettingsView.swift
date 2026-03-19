import SwiftUI

struct SettingsView: View {
    var body: some View {
        ProfileHomeView()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
