import SwiftUI
import PhotosUI
import UIKit

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let hPad: CGFloat = 16

    private enum Field {
        case businessName, representativeName, representativeRole
        case specialties, zipCode, phone, websiteURL
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    progressHeader
                    heroSection

                    switch vm.step {
                    case .profile:  profileStep
                    case .presence: presenceStep
                    }
                }
                .padding(.horizontal, hPad)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        appState.skipOnboarding()
                        // No dismiss() — skipOnboarding() sets showOnboarding=false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
            .task {
                await vm.loadInitialState(
                    userId: appState.authenticatedUserId,
                    currentUser: appState.currentUser
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadSelectedPhoto(newItem)
                }
            }
            .alert("Onboarding Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .interactiveDismissDisabled(vm.isLoading)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Step \(vm.step.index) of \(OnboardingViewModel.Step.allCases.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(vm.step == .profile ? "Profile" : "Presence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.hushhPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.hushhPrimary.opacity(0.12))
                    )
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))

                    Capsule()
                        .fill(Color.hushhPrimary)
                        .frame(width: proxy.size.width * vm.progressValue)
                        .animation(.easeInOut(duration: 0.35), value: vm.progressValue)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.step.title)
                .font(.largeTitle.bold())
            Text(vm.step.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Step 1: Profile

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Identity card
            GroupCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Who should RIAs see?")
                        .font(.headline)
                    Text("This becomes the public face of your profile.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                FormField(title: "Business Name", placeholder: "Example: Northlake Wealth", text: $vm.businessName)
                    .focused($focusedField, equals: .businessName)
                    .textContentType(.organizationName)

                FormField(title: "Representative Name", placeholder: "Your public-facing name", text: $vm.representativeName)
                    .focused($focusedField, equals: .representativeName)
                    .textContentType(.name)

                FormField(title: "Representative Role", placeholder: "Founder, Lead Advisor, Partner…", text: $vm.representativeRole)
                    .focused($focusedField, equals: .representativeRole)
            }

            // Categories card
            GroupCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What do you want to be known for?")
                        .font(.headline)
                    Text("Pick the categories that should anchor your deck presence.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                FlowLayout(spacing: 10) {
                    ForEach(OnboardingViewModel.availableCategories) { category in
                        ChipButton(
                            title: category.label,
                            systemImage: category.icon,
                            isSelected: vm.selectedCategories.contains(category.id)
                        ) {
                            vm.toggleCategory(category.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Presence

    private var presenceStep: some View {
        GroupCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("How should you appear on deck?")
                    .font(.headline)
                Text("Upload a real photo, add your ZIP, and share the contact details other RIAs need.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            PhotoUploadField(
                selectedImage: vm.selectedPhotoPreviewImage,
                existingPhotoURL: vm.existingPhotoURL,
                hasPhoto: vm.hasPhoto,
                selection: $selectedPhotoItem
            )

            FormField(title: "Specialties", placeholder: "Retirement planning, business-owner tax strategy…", text: $vm.specialties)
                .focused($focusedField, equals: .specialties)

            FormField(title: "PIN Code", placeholder: "98033", text: $vm.zipCode)
                .focused($focusedField, equals: .zipCode)
                .keyboardType(.numbersAndPunctuation)

            FormField(title: "Phone", placeholder: "8004482372", text: phoneBinding)
                .focused($focusedField, equals: .phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)

            FormField(title: "Website (Optional)", placeholder: "yourfirm.com", text: $vm.websiteURL)
                .focused($focusedField, equals: .websiteURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 10) {
            if let secondaryTitle = vm.secondaryButtonTitle {
                Button(secondaryTitle) {
                    vm.goBack()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Button {
                focusedField = nil
                if vm.step == .profile {
                    vm.goToNextStep()
                } else if let userId = appState.authenticatedUserId {
                    Task {
                        do {
                            let profile = try await vm.submit(userId: userId)
                            appState.completeOnboarding(with: profile)
                            // No dismiss() — completeOnboarding() sets showOnboarding=false
                        } catch {
                            if vm.errorMessage == nil {
                                vm.errorMessage = "We couldn't finish your RIA profile right now. Please try again."
                            }
                        }
                    }
                }
            } label: {
                Text(vm.primaryButtonTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.hushhPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isActionDisabled)
            .opacity(isActionDisabled ? 0.4 : 1)
        }
        .padding(.horizontal, hPad)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }

    private var isActionDisabled: Bool {
        (vm.step == .profile && !vm.isProfileStepValid) ||
        (vm.step == .presence && !vm.isPresenceStepValid) ||
        vm.isLoading
    }

    private var phoneBinding: Binding<String> {
        Binding(
            get: { vm.phone },
            set: { newValue in
                vm.updatePhoneInput(newValue)
                if vm.phone.count == 10, focusedField == .phone {
                    focusedField = nil
                }
            }
        )
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            vm.setSelectedPhotoData(nil)
            return
        }

        do {
            let data = try await item.loadTransferable(type: Data.self)
            vm.setSelectedPhotoData(data)
        } catch {
            vm.errorMessage = "Couldn't prepare your photo upload. Please try again."
        }
    }
}

// MARK: - GroupCard

/// An iOS-native inset grouped section card.
private struct GroupCard<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - FormField

private struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
        }
    }
}

private struct PhotoUploadField: View {
    let selectedImage: UIImage?
    let existingPhotoURL: String?
    let hasPhoto: Bool
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Profile Photo")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Required")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasPhoto ? .green : .orange)
            }

            HStack(spacing: 14) {
                photoPreview

                VStack(alignment: .leading, spacing: 6) {
                    Text(hasPhoto ? "Your uploaded photo will appear across the deck and profile." : "Upload a gallery photo for your public RIA profile.")
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Text("We'll upload it to secure Hushh storage and save the generated URL for your profile.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                Label(hasPhoto ? "Replace Photo" : "Upload Photo", systemImage: "photo.on.rectangle.angled")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.hushhPrimary.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.hushhPrimary)
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else if let existingPhotoURL, let url = URL(string: existingPhotoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholderPreview
                }
            }
            .frame(width: 78, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            placeholderPreview
        }
    }

    private var placeholderPreview: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.systemBackground))
            .frame(width: 78, height: 78)
            .overlay(
                Image(systemName: "person.crop.square.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
    }
}

// MARK: - ChipButton

private struct ChipButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.hushhPrimary : Color(.systemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
