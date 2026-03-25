import SwiftUI

struct EmptyDeckView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isGuestBrowsingMode {
                GuestBrowsingCard(
                    title: "Keep your guest deck moving",
                    message: "Sign in to sync your saved and passed cards, unlock chats, and start building your verified profile.",
                    buttonTitle: "Sign In to Continue"
                ) {
                    appState.presentGuestSignIn()
                }
            } else if appState.needsVerifiedProfileCompletion {
                VerifiedProfileCompletionCard(
                    title: "Finish setup to publish your profile",
                    message: "Resume your verified profile lookup so the rest of the app reflects your real advisor identity.",
                    buttonTitle: "Resume Lookup"
                )
            } else {
                ContentUnavailableView {
                    Label("End of Deck", systemImage: "checkmark.circle")
                } description: {
                    Text("You've seen all available RIAs. Jump into your saved advisors or restart the stack.")
                } actions: {
                    Button("Open Saved RIAs") {
                        appState.triggerGatedAction(.openActivity(section: .saved))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Guest Browsing Card

enum GuestBrowsingCardStyle {
    case prominent
    case compact
}

struct GuestBrowsingCard: View {
    let title: String
    let message: String
    let buttonTitle: String
    var style: GuestBrowsingCardStyle = .prominent
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(style == .prominent ? .headline : .subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundStyle(.blue)
                    .font(style == .prominent ? .title2 : .body)
            }

            Text(message)
                .font(style == .prominent ? .subheadline : .footnote)
                .foregroundStyle(.secondary)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Verified Profile Completion Card

enum VerifiedProfileCompletionCardStyle {
    case prominent
    case compact
}

struct VerifiedProfileCompletionCard: View {
    @EnvironmentObject var appState: AppState

    let title: String
    let message: String
    let buttonTitle: String
    var style: VerifiedProfileCompletionCardStyle = .prominent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(style == .prominent ? .headline : .subheadline.weight(.semibold))
            } icon: {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(.orange)
                    .font(style == .prominent ? .title2 : .body)
            }

            Text(message)
                .font(style == .prominent ? .subheadline : .footnote)
                .foregroundStyle(.secondary)

            Button {
                appState.resumeVerifiedProfileCompletion()
            } label: {
                Text(buttonTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    EmptyDeckView()
        .environmentObject(AppState())
}
