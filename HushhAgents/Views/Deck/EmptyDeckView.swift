import SwiftUI

struct EmptyDeckView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("You reached the end of the deck")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Text("Jump into your saved RIAs or restart the stack.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                appState.triggerGatedAction(.openActivity(section: .saved))
            } label: {
                Text("Open Saved RIAs")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.hushhPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 32)
            .padding(.top, 4)
        }
        .padding(16)
    }
}

#Preview {
    EmptyDeckView()
        .environmentObject(AppState())
}
