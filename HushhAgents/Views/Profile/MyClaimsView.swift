import SwiftUI

struct MyClaimsView: View {
    var body: some View {
        List {
            ContentUnavailableView(
                "No Claims Yet",
                systemImage: "star.slash",
                description: Text("Your lead requests will appear here")
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .navigationTitle("My Claims")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        MyClaimsView()
    }
}
