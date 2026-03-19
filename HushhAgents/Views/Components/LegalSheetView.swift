import SwiftUI

/// A reusable iOS bottom sheet for displaying legal documents (Privacy Policy, Terms of Service).
struct LegalSheetView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let icon: String
    let content: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Icon header
                    HStack {
                        Spacer()
                        Image(systemName: icon)
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Body text
                    Text(content)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            LegalSheetView(
                title: "Privacy Policy",
                icon: "hand.raised.fill",
                content: "Sample privacy policy content goes here..."
            )
        }
}
