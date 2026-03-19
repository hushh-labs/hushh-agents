import SwiftUI

struct RatingStarsView: View {
    let rating: Double
    let reviewCount: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                starImage(for: index)
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            Text("(\(reviewCount))")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func starImage(for index: Int) -> some View {
        let threshold = Double(index)
        if rating >= threshold {
            Image(systemName: "star.fill")
        } else if rating >= threshold - 0.5 {
            Image(systemName: "star.leadinghalf.filled")
        } else {
            Image(systemName: "star")
                .foregroundColor(Color(.systemGray4))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        RatingStarsView(rating: 4.5, reviewCount: 22)
        RatingStarsView(rating: 3.0, reviewCount: 8)
        RatingStarsView(rating: 5.0, reviewCount: 1)
    }
    .padding()
}
