import SwiftUI

struct CategoryBadge: View {
    let category: String

    var body: some View {
        Text(category)
            .font(.caption2.weight(.medium))
            .foregroundColor(.blue)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        CategoryBadge(category: "Financial Advising")
        CategoryBadge(category: "Insurance")
    }
    .padding()
}
