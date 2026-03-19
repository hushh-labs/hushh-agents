import SwiftUI

struct CardStackView: View {
    @ObservedObject var deckVM: DeckViewModel
    let availableHeight: CGFloat
    var onTapAgent: ((KirklandAgent) -> Void)?

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let cardWidth = max(geo.size.width, 0)
            let cardHeight = max(availableHeight - 16, 0)
            let stackOffset: CGFloat = 12

            ZStack {
                if deckVM.topCards.isEmpty {
                    EmptyDeckView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(Array(deckVM.topCards.prefix(3).reversed().enumerated()), id: \.element.id) { index, agent in
                        let isTop = (agent.id == deckVM.topCards.first?.id)
                        let reverseIndex = deckVM.topCards.prefix(3).count - 1 - index

                        AgentCardView(
                            agent: agent,
                            maxCardHeight: cardHeight,
                            swipeStatus: deckVM.status(for: agent)
                        ) {
                            onTapAgent?(agent)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        .scaleEffect(isTop ? 1.0 : 1.0 - (CGFloat(reverseIndex) * 0.025))
                        .opacity(isTop ? 1.0 : 0.96 - (Double(reverseIndex) * 0.04))
                        .offset(y: isTop ? 0 : CGFloat(reverseIndex) * stackOffset)
                        .offset(x: isTop ? dragOffset.width : 0)
                        .rotationEffect(isTop ? .degrees(Double(dragOffset.width / 22)) : .zero)
                        .shadow(
                            color: .black.opacity(isTop ? 0.06 : 0.02),
                            radius: isTop ? 12 : 6,
                            x: 0,
                            y: isTop ? 6 : 3
                        )
                        .overlay(swipeOverlay(isTop: isTop))
                        .zIndex(isTop ? 1 : 0)
                        .gesture(isTop ? dragGesture : nil)
                        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Swipe Overlay

    @ViewBuilder
    private func swipeOverlay(isTop: Bool) -> some View {
        if isTop {
            ZStack {
                // Left drag → PASS
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                    Text("PASS")
                }
                .font(.title2.bold())
                .foregroundStyle(.red)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.red, lineWidth: 2)
                        )
                )
                .rotationEffect(.degrees(-15))
                .opacity(Double(-dragOffset.width / 100).clamped(to: 0...1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(20)

                // Right drag → LIKE
                HStack(spacing: 6) {
                    Image(systemName: "heart.circle.fill")
                    Text("SAVE")
                }
                .font(.title2.bold())
                .foregroundStyle(.green)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.green, lineWidth: 2)
                        )
                )
                .rotationEffect(.degrees(15))
                .opacity(Double(dragOffset.width / 100).clamped(to: 0...1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20)
            }
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                guard let topAgent = deckVM.topCards.first else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                    return
                }

                let threshold: CGFloat = 100
                if value.translation.width > threshold {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = CGSize(width: 500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        deckVM.swipe(topAgent, direction: .interested)
                        dragOffset = .zero
                    }
                } else if value.translation.width < -threshold {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = CGSize(width: -500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        deckVM.swipe(topAgent, direction: .pass)
                        dragOffset = .zero
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }
}

// MARK: - Clamping Helper

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    CardStackView(deckVM: DeckViewModel(), availableHeight: 520)
}
