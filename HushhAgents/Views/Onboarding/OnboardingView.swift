import SwiftUI

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

struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    @FocusState private var focusedField: Field?

    private let hPad: CGFloat = 16

    private enum Field {
        case query
        case phone
    }

    init(viewModel: OnboardingViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    @MainActor
    init() {
        _vm = StateObject(wrappedValue: OnboardingViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                switch vm.phase {
                case .loading:
                    loadingState
                case .nameEntry:
                    nameEntryForm
                default:
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            previewHeroSection

                            switch vm.phase {
                            case .preview:
                                previewSection
                            case .noMatch:
                                noMatchSection
                            case .error:
                                errorSection
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, hPad)
                        .padding(.top, 8)
                        .padding(.bottom, 140)
                    }
                    .scrollIndicators(.hidden)
                    .background(nameEntryBackground.ignoresSafeArea())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
                }
            }
            .toolbar {
                if canSkipOnboarding {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") {
                            appState.skipOnboarding()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.regularMaterial)
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if vm.phase != .loading {
                    bottomActionBar
                }
            }
            .task {
                await vm.loadInitialState(
                    userId: appState.authenticatedUserId,
                    currentUser: appState.currentUser
                )
            }
            .alert("Onboarding Error", isPresented: Binding(
                get: { vm.alertMessage != nil },
                set: { if !$0 { vm.alertMessage = nil } }
            )) {
                Button("OK") { vm.alertMessage = nil }
            } message: {
                Text(vm.alertMessage ?? "")
            }
            .interactiveDismissDisabled(vm.isBusy)
        }
    }

    private var canSkipOnboarding: Bool {
        appState.onboardingPresentationMode == .initial && vm.phase == .nameEntry
    }

    private var primaryActionTitle: String {
        switch vm.phase {
        case .nameEntry:
            return "Find My RIA Profile"
        case .preview:
            return appState.onboardingPrimaryActionTitle
        case .noMatch:
            return "Search Again"
        case .error:
            return "Try Again"
        case .loading:
            return ""
        }
    }

    private var primaryActionDisabled: Bool {
        switch vm.phase {
        case .nameEntry:
            return !vm.canSubmitQuery
        case .preview:
            return !vm.canSavePreview
        case .noMatch, .error:
            return false
        case .loading:
            return true
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image("HushhLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(heroTitle)
                        .font(.hushhHeading(.title))
                    Text(heroSubtitle)
                        .font(.hushhBody(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }

            if vm.phase == .preview, let preview = vm.previewContent {
                Text("Based on public records for \(preview.fullName).")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.hushhPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.hushhPrimary.opacity(0.12))
                    )
            }
        }
    }

    private var heroTitle: String {
        switch vm.phase {
        case .nameEntry:
            return "Build Your RIA Profile"
        case .loading:
            return "Preparing your dossier"
        case .preview:
            return "Review Your Verified Profile"
        case .noMatch:
            return "We Couldn't Match That Name"
        case .error:
            return "Profile Lookup Paused"
        }
    }

    private var heroSubtitle: String {
        switch vm.phase {
        case .nameEntry:
            if appState.pendingGatedAction != nil {
                return "Enter your public name first. We’ll verify your profile, fetch your image, and then continue to \(appState.pendingDestinationLabel.lowercased())."
            }
            return "Enter your public name and we'll verify your profile, fetch your image, and prepare your deck presence."
        case .loading:
            return "We're handling verification, research, and image ranking in the background."
        case .preview:
            return "Confirm the public profile we found, add your phone number, and continue."
        case .noMatch:
            return "Try a different spelling or firm-associated name so we can verify the right public record."
        case .error:
            return "The research service hit a temporary issue. Retry the lookup when you're ready."
        }
    }

    private var nameEntryForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                nameEntryHero
                nameEntryInputCard
                nameEntryAssuranceCard

                if appState.pendingGatedAction != nil {
                    nameEntryContinuationCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 156)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(nameEntryBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Preview Hero (for non-nameEntry phases)

    private var nameEntryBackground: some View {
        ZStack {
            Color(.systemGroupedBackground)

            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.hushhPrimary.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 24)
                .offset(x: 130, y: -180)

            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: -150, y: -120)
        }
    }

    private var nameEntryHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                    )

                Image("HushhLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text(heroTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(heroSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 8)
    }

    private var nameEntryInputCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Public advisor or firm name")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Use the exact name that appears in FINRA, SEC, or firm-facing public profiles.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(focusedField == .query ? Color.hushhPrimary : .secondary)
                    .frame(width: 24)

                TextField(
                    "",
                    text: Binding(
                        get: { vm.query },
                        set: vm.updateQuery
                    ),
                    prompt: Text("ANA ROUMENOVA CARTER")
                        .foregroundStyle(.tertiary)
                )
                .focused($focusedField, equals: .query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .font(.title3.weight(.semibold))
                .onSubmit {
                    Task { await vm.startLookup() }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        focusedField == .query ? Color.hushhPrimary.opacity(0.9) : Color.black.opacity(0.06),
                        lineWidth: focusedField == .query ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                if let queryValidationMessage = vm.queryValidationMessage {
                    validationMessage(queryValidationMessage)
                }

                Text("We only use public record data to verify the right advisor or firm before generating your profile.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, y: 10)
    }

    private var nameEntryAssuranceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What happens next")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "checkmark.shield.fill",
                    title: "Verify regulatory records",
                    message: "We confirm the public match before anything is added to your profile."
                )

                OnboardingFeatureRow(
                    icon: "sparkles.rectangle.stack.fill",
                    title: "Build the profile for you",
                    message: "Public facts, firm details, and availability are prepared automatically."
                )

                OnboardingFeatureRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Find the best public image",
                    message: "We prefer a trusted headshot and fall back safely when one is not available."
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }

    private var nameEntryContinuationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.turn.down.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.hushhPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 6) {
                Text("Continue after setup")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Once your verified profile is ready, we’ll continue to \(appState.pendingDestinationLabel.lowercased()).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }

    private var previewHeroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 70, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.78), lineWidth: 1)
                    )

                Image("HushhLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text(heroTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(heroSubtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if vm.phase == .preview, let preview = vm.previewContent {
                Text("Based on public records for \(preview.fullName).")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.hushhPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.hushhPrimary.opacity(0.12))
                    )
            }
        }
        .padding(.top, 6)
    }

    private var nameEntrySection: some View {
        GroupCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your public advisor name?")
                    .font(.headline)
                Text("Use the name you expect to appear in FINRA, SEC, or firm-facing public profiles.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            FormField(
                title: "Name",
                placeholder: "Example: ANA ROUMENOVA CARTER",
                text: Binding(
                    get: { vm.query },
                    set: vm.updateQuery
                )
            )
            .focused($focusedField, equals: .query)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .onSubmit {
                Task { await vm.startLookup() }
            }

            if let queryValidationMessage = vm.queryValidationMessage {
                validationMessage(queryValidationMessage)
            }

            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .foregroundStyle(Color.hushhPrimary)
                Text("We'll verify regulatory records first, then build the rest of your profile automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let preview = vm.previewContent {
                GroupCard {
                    HStack(alignment: .center, spacing: 16) {
                        PreviewAvatar(imageURL: preview.imageURL, initials: preview.initials)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(preview.fullName)
                                .font(.system(.title3, design: .rounded, weight: .bold))

                            if !preview.firmName.isEmpty {
                                Text(preview.firmName)
                                    .font(.hushhBody(.subheadline, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }

                            if !preview.locationLine.isEmpty {
                                Label(preview.locationLine, systemImage: "mappin.and.ellipse")
                                    .font(.hushhBody(.caption))
                                    .foregroundStyle(.secondary)
                            }

                            Label(preview.representativeRole, systemImage: "person.text.rectangle")
                                .font(.hushhBody(.caption, weight: .medium))
                                .foregroundStyle(Color.hushhPrimary)
                        }
                    }

                    // CRD badge — prominent if present
                    if let crd = preview.crdNumber, !crd.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("CRD #\(crd)")
                                .font(.hushhBody(.subheadline, weight: .semibold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Verified")
                                .font(.hushhBody(.caption, weight: .medium))
                                .foregroundStyle(.green)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.green.opacity(0.08))
                        )
                    }
                }

                GroupCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Executive Summary")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                        Text(
                            preview.executiveSummary.isEmpty
                                ? "Verified during public profile lookup."
                                : preview.executiveSummary
                        )
                        .font(.body)
                        .foregroundStyle(.secondary)
                    }

                    if !preview.keyFacts.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Facts")
                                .font(.system(.headline, design: .rounded, weight: .semibold))

                            ForEach(preview.keyFacts, id: \.self) { fact in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.hushhPrimary)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    Text(fact)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !preview.categories.isEmpty {
                    GroupCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Derived Categories")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                            FlowLayout(spacing: 10) {
                                ForEach(preview.categories) { category in
                                    ReadonlyChip(title: category.label, systemImage: category.icon)
                                }
                            }
                        }
                    }
                }

                GroupCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact for Your Deck Card")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                        Text("Add your phone number to publish this profile on the deck.")
                            .font(.hushhBody(.subheadline))
                            .foregroundStyle(.secondary)
                    }

                    // Phone field with +1 country code
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 0) {
                            Text("+1")
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(
                                    Color(.tertiarySystemFill)
                                )

                            TextField("8135551212", text: Binding(
                                get: { vm.phone },
                                set: vm.updatePhoneInput
                            ))
                            .focused($focusedField, equals: .phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if let phoneValidationMessage = vm.phoneValidationMessage {
                        validationMessage(phoneValidationMessage)
                    }

                    // Clickable website
                    if !preview.websiteURL.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Website")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if let url = URL(string: preview.websiteURL) {
                                Link(destination: url) {
                                    HStack(spacing: 6) {
                                        Text(preview.websiteURL)
                                            .font(.hushhBody(.subheadline))
                                            .foregroundStyle(Color.hushhPrimary)
                                            .lineLimit(1)
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                            .foregroundStyle(Color.hushhPrimary)
                                    }
                                }
                            } else {
                                Text(preview.websiteURL)
                                    .font(.hushhBody(.subheadline))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                // Verified Sources — show as a list
                if !preview.verifiedSources.isEmpty {
                    GroupCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verified Sources")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                            Text("\(preview.verifiedSources.count) source\(preview.verifiedSources.count == 1 ? "" : "s") confirmed this profile.")
                                .font(.hushhBody(.caption))
                                .foregroundStyle(.secondary)
                        }

                        ForEach(preview.verifiedSources) { source in
                            if let url = URL(string: source.url) {
                                Link(destination: url) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundStyle(.green)
                                            .font(.body)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(source.platform)
                                                .font(.hushhBody(.subheadline, weight: .semibold))
                                                .foregroundStyle(.primary)
                                            Text(source.label)
                                                .font(.hushhBody(.caption))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer(minLength: 0)

                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption2)
                                            .foregroundStyle(Color.hushhPrimary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundStyle(.green)
                                        .font(.body)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(source.platform)
                                            .font(.hushhBody(.subheadline, weight: .semibold))
                                        Text(source.label)
                                            .font(.hushhBody(.caption))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
    }

    private var noMatchSection: some View {
        GroupCard {
            VStack(alignment: .leading, spacing: 14) {
                Label {
                    Text("No confident match yet")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                } icon: {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundStyle(Color.hushhPrimary)
                }

                Text(vm.noMatchMessage ?? "We couldn't confidently match that name to FINRA or SEC records.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledValue(title: "Searched", value: vm.query)
                }
            }
        }
    }

    private var errorSection: some View {
        GroupCard {
            VStack(alignment: .leading, spacing: 14) {
                Label {
                    Text("Temporary service issue")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }

                Text(vm.errorStateMessage ?? "We couldn't complete the profile lookup right now.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledValue(title: "Lookup Name", value: vm.query)
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 86, height: 86)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )

                    Image("HushhLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                }
                .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                VStack(spacing: 12) {
                    Text(vm.loadingTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    Text(vm.loadingSubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(Color.hushhPrimary)
                        .scaleEffect(1.15)

                    if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Searching for \(vm.query)")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == 1 ? Color.hushhPrimary : Color.hushhPrimary.opacity(0.22))
                            .frame(width: index == 1 ? 30 : 16, height: 6)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 34)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.82), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 24, y: 12)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .background(nameEntryBackground.ignoresSafeArea())
    }

    private var bottomActionBar: some View {
        VStack(spacing: 10) {
            if vm.phase == .preview {
                Button("Search Again") {
                    focusedField = nil
                    vm.searchAgain()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.88))
                )
            }

            Button {
                focusedField = nil
                switch vm.phase {
                case .nameEntry:
                    Task { await vm.startLookup() }
                case .preview:
                    if let userId = appState.authenticatedUserId {
                        Task {
                            do {
                                let profile = try await vm.submit(userId: userId)
                                appState.completeOnboarding(with: profile)
                            } catch {
                                if vm.alertMessage == nil && vm.phoneValidationMessage == nil {
                                    vm.alertMessage = "We couldn't publish your RIA profile right now. Please try again."
                                }
                            }
                        }
                    }
                case .noMatch, .error:
                    if vm.phase == .error {
                        Task { await vm.startLookup() }
                    } else {
                        vm.searchAgain()
                    }
                case .loading:
                    break
                }
            } label: {
                if vm.isBusy {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                        Text(primaryActionTitle)
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    Text(primaryActionTitle)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
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
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .disabled(primaryActionDisabled)
            .opacity(primaryActionDisabled ? 0.45 : 1)
            .shadow(color: Color.hushhPrimary.opacity(0.22), radius: 14, y: 8)
        }
        .padding(.horizontal, hPad)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func validationMessage(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }
}

private struct GroupCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 18, y: 8)
    }
}

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.hushhPrimary.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hushhPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
        }
    }
}

private struct ReadonlyChip: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.hushhPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(Color.hushhPrimary.opacity(0.12))
        )
    }
}

private struct LabeledValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.8))
        )
    }
}

private struct PreviewAvatar: View {
    let imageURL: String?
    let initials: String

    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.hushhPrimary.opacity(0.12))
                    .overlay(
                        Text(initials)
                            .font(.title2.bold())
                            .foregroundStyle(Color.hushhPrimary)
                    )
            }
        }
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }
}

#Preview("Name Entry") {
    OnboardingView(viewModel: .previewViewModel(phase: .nameEntry))
        .environmentObject(AppState.preview(onboardingMode: .initial))
}

#Preview("Loading") {
    OnboardingView(viewModel: .previewViewModel(phase: .loading))
        .environmentObject(AppState.preview(onboardingMode: .initial))
}

#Preview("Preview") {
    OnboardingView(viewModel: .previewViewModel(phase: .preview))
        .environmentObject(AppState.preview(onboardingMode: .initial))
}

#Preview("No Match") {
    OnboardingView(viewModel: .previewViewModel(phase: .noMatch))
        .environmentObject(AppState.preview(onboardingMode: .initial))
}

#Preview("Error") {
    OnboardingView(viewModel: .previewViewModel(phase: .error))
        .environmentObject(AppState.preview(onboardingMode: .editProfile))
}

@MainActor
private extension AppState {
    static func preview(onboardingMode: OnboardingPresentationMode) -> AppState {
        let appState = AppState()
        let userId = UUID()
        appState.sessionStatus = .authenticated(userId: userId)
        appState.currentUser = AppUser(
            rowId: nil,
            id: userId,
            email: "preview@hushh.ai",
            phone: "8135551212",
            fullName: nil,
            avatarUrl: nil,
            onboardingStep: "welcome",
            profileVisibility: "draft",
            discoveryEnabled: true,
            metadata: nil
        )
        appState.onboardingPresentationMode = onboardingMode
        appState.showOnboarding = true
        return appState
    }
}
