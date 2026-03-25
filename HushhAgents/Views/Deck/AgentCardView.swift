import SwiftUI

struct AgentCardView: View {
    let agent: KirklandAgent
    let maxCardHeight: CGFloat?
    let swipeStatus: String?
    var onViewProfile: (() -> Void)? = nil

    private var previewFallbackCardHeight: CGFloat {
        let fallback: CGFloat = UIScreen.main.bounds.width >= 430 ? 620 : 560
        return max(maxCardHeight ?? fallback, 0)
    }

    private let minHeroHeight: CGFloat = 200
    private let maxHeroHeight: CGFloat = 320
    private let minimumInfoHeight: CGFloat = 170

    private var statusBadge: (title: String, icon: String, tint: Color)? {
        switch swipeStatus {
        case "selected": return ("Saved", "heart.fill", .green)
        case "rejected": return ("Passed", "xmark.circle.fill", .red)
        default: return nil
        }
    }

    var body: some View {
        GeometryReader { geo in
            let containerHeight = geo.size.height > 0 ? geo.size.height : previewFallbackCardHeight
            let heroUpperBound = max(containerHeight - minimumInfoHeight, minHeroHeight)
            let heroHeight = min(
                max(containerHeight * 0.55, minHeroHeight),
                min(maxHeroHeight, heroUpperBound)
            )
            let infoHeight = max(containerHeight - heroHeight, 0)

            VStack(spacing: 0) {
                heroSection(height: heroHeight)
                infoSection(height: infoHeight)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private func heroSection(height: CGFloat) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Text(agent.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                if let city = agent.city, let state = agent.state {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .symbolRenderingMode(.monochrome)
                        Text("\(city), \(state)")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .minimumScaleFactor(0.85)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .padding(.top, 40)

            if let badge = statusBadge {
                VStack {
                    HStack {
                        Spacer()
                        Label(badge.title, systemImage: badge.icon)
                            .symbolRenderingMode(.monochrome)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(badge.tint))
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background {
            AgentImageView(
                candidates: agent.deckImageCandidates,
                fallbackName: agent.name,
                fillMode: true
            )
        }
        .overlay {
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        .clipped()
    }

    private func infoSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            RatingStarsView(
                rating: agent.avgRating ?? 0,
                reviewCount: agent.reviewCount
            )
            .layoutPriority(2)

            if !agent.categories.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        ForEach(agent.categories.prefix(3), id: \.self) { category in
                            CategoryBadge(category: category)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(agent.categories.prefix(3), id: \.self) { category in
                            CategoryBadge(category: category)
                        }
                    }
                }
            }

            if let bio = agent.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            Button {
                onViewProfile?()
            } label: {
                HStack(spacing: 6) {
                    Text("View Complete Profile")
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )
            }
            .layoutPriority(3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .background(Color(.secondarySystemGroupedBackground))
        .clipped()
    }
}

#Preview {
    AgentCardView(agent: PreviewData.sampleAgent, maxCardHeight: 560, swipeStatus: nil)
        .padding()
        .background(Color(.systemGroupedBackground))
}
