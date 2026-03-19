import SwiftUI

struct SwipeActionButtons: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var deckVM: DeckViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Pass button
            ActionCircleButton(
                systemName: "xmark",
                size: 60,
                tint: Color(.secondaryLabel)
            ) {
                Haptics.impact(.light)
                if let agent = deckVM.topCards.first {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        deckVM.swipe(agent, direction: .pass)
                    }
                }
            }

            // Save / Saved center button
            Button {
                Haptics.impact(.medium)
                appState.triggerGatedAction(.openActivity(section: .saved))
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square.fill")
                        .symbolRenderingMode(.monochrome)
                    Text("Saved")
                        .fontWeight(.semibold)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.hushhPrimary)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Like button
            ActionCircleButton(
                systemName: "heart.fill",
                size: 60,
                tint: Color(red: 1.0, green: 0.29, blue: 0.45)
            ) {
                Haptics.impact(.light)
                if let agent = deckVM.topCards.first {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        deckVM.swipe(agent, direction: .interested)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Action Circle Button

private struct ActionCircleButton: View {
    let systemName: String
    let size: CGFloat
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.37, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                )
                .overlay(
                    Circle()
                        .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - SwipeActionDock

struct SwipeActionDock<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
    }
}

#Preview {
    SwipeActionDock {
        SwipeActionButtons(deckVM: DeckViewModel())
            .environmentObject(AppState())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
