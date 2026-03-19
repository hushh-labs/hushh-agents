import SwiftUI

struct PassedAgentsView: View {
    var body: some View {
        List {
            ContentUnavailableView(
                "No Passed Agents",
                systemImage: "xmark.circle",
                description: Text("Agents you've passed on will appear here")
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Passed Agents")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        PassedAgentsView()
    }
}
