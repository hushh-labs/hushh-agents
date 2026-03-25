import SwiftUI

struct CategoryBadge: View {
    let category: String

    var body: some View {
        Text(category)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

#Preview {
    HStack {
        CategoryBadge(category: "Financial Advising")
        CategoryBadge(category: "Insurance")
    }
    .padding()
}
