import SwiftUI

struct EmptyDeckView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isGuestBrowsingMode {
                GuestBrowsingCard(
                    title: "Keep your guest deck moving",
                    message: "Sign in to sync your saved and passed cards, unlock chats and activity, and start building your verified profile.",
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
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.monochrome)

                    Text("You reached the end of the deck")
                        .font(.hushhHeading(.title3))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Jump into your saved RIAs or restart the stack.")
                        .font(.hushhBody(.subheadline))
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
            }
        }
        .padding(16)
    }
}

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

    private var iconSize: CGFloat {
        style == .prominent ? 48 : 36
    }

    private var titleFont: Font {
        style == .prominent
            ? .system(.title3, design: .rounded, weight: .bold)
            : .system(.headline, design: .rounded, weight: .semibold)
    }

    private var messageFont: Font {
        style == .prominent ? .system(.subheadline) : .system(.footnote)
    }

    private var horizontalPadding: CGFloat {
        style == .prominent ? 18 : 14
    }

    private var verticalPadding: CGFloat {
        style == .prominent ? 18 : 14
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.hushhPrimary.opacity(0.12))
                        .frame(width: iconSize + 10, height: iconSize + 10)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(Color.hushhPrimary)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(titleFont)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(messageFont)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.hushhPrimary,
                                Color.hushhPrimary.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
    }
}

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

    private var iconSize: CGFloat {
        style == .prominent ? 48 : 36
    }

    private var titleFont: Font {
        style == .prominent
            ? .system(.title3, design: .rounded, weight: .bold)
            : .system(.headline, design: .rounded, weight: .semibold)
    }

    private var messageFont: Font {
        style == .prominent ? .system(.subheadline) : .system(.footnote)
    }

    private var horizontalPadding: CGFloat {
        style == .prominent ? 18 : 14
    }

    private var verticalPadding: CGFloat {
        style == .prominent ? 18 : 14
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.hushhPrimary.opacity(0.12))
                        .frame(width: iconSize + 10, height: iconSize + 10)

                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(Color.hushhPrimary)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(titleFont)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(messageFont)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                appState.resumeVerifiedProfileCompletion()
            } label: {
                Text(buttonTitle)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.hushhPrimary,
                                Color.hushhPrimary.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
    }
}

#Preview {
    EmptyDeckView()
        .environmentObject(AppState())
}
