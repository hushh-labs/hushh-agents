import SwiftUI

// MARK: - Flow Layout (unchanged — used for category chips)

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

// MARK: - Onboarding View

struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    @FocusState private var focusedField: Field?

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
                case .preview:
                    previewForm
                case .noMatch:
                    noMatchForm
                case .error:
                    errorForm
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if canSkipOnboarding {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") {
                            appState.skipOnboarding()
                        }
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

    // MARK: - Navigation

    private var navigationTitle: String {
        switch vm.phase {
        case .nameEntry: return "Set Up Your Profile"
        case .loading:   return "Searching…"
        case .preview:   return "Your Profile Preview"
        case .noMatch:   return "No Match Found"
        case .error:     return "Something Went Wrong"
        }
    }

    private var canSkipOnboarding: Bool {
        appState.onboardingPresentationMode == .initial && vm.phase == .nameEntry
    }

    private var primaryActionTitle: String {
        switch vm.phase {
        case .nameEntry: return "Search Public Records"
        case .preview:   return appState.onboardingPrimaryActionTitle
        case .noMatch:   return "Search Again"
        case .error:     return "Try Again"
        case .loading:   return ""
        }
    }

    private var primaryActionDisabled: Bool {
        switch vm.phase {
        case .nameEntry: return !vm.canSubmitQuery
        case .preview:   return !vm.canSavePreview
        case .noMatch, .error: return false
        case .loading:   return true
        }
    }

    // MARK: - Name Entry

    private var nameEntryForm: some View {
        Form {
            Section {
                Text(nameEntrySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(
                        "ANA ROUMENOVA CARTER",
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
                }

                if let queryValidationMessage = vm.queryValidationMessage {
                    Label(queryValidationMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Your name or firm")
            } footer: {
                Text("Match the spelling used in FINRA BrokerCheck or SEC IAPD for the best results. We only access publicly available records.")
            }

            Section("What happens next") {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cross-reference regulatory filings")
                            .font(.subheadline.weight(.medium))
                        Text("We check FINRA BrokerCheck, SEC IAPD, and state records to confirm your identity.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assemble your professional dossier")
                            .font(.subheadline.weight(.medium))
                        Text("Firm history, credentials, specialties, and key facts — compiled from verified sources.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .foregroundStyle(.blue)
                }

                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select your best photo")
                            .font(.subheadline.weight(.medium))
                        Text("We scan public sources for professional headshots and rank them by quality.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundStyle(.orange)
                }
            }

            if appState.pendingGatedAction != nil {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continue after setup")
                                .font(.subheadline.weight(.medium))
                            Text("Once verified, we'll continue to \(appState.pendingDestinationLabel.lowercased()).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var nameEntrySubtitle: String {
        if appState.pendingGatedAction != nil {
            return "Type your name or firm exactly as it appears in regulatory filings. Our research engine pulls verified data from FINRA, SEC, and trusted public sources — then we'll continue to \(appState.pendingDestinationLabel.lowercased())."
        }
        return "Type your name or firm exactly as it appears in regulatory filings — our research engine does the rest. We pull verified data from FINRA, SEC, and trusted public sources to build your profile automatically."
    }

    // MARK: - Preview

    private var previewForm: some View {
        Form {
            if let preview = vm.previewContent {
                // Profile header
                Section {
                    HStack(spacing: 14) {
                        PreviewAvatar(imageURL: preview.imageURL, initials: preview.initials)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(preview.fullName)
                                .font(.headline)

                            if !preview.firmName.isEmpty {
                                Text(preview.firmName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if !preview.locationLine.isEmpty {
                                Label(preview.locationLine, systemImage: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Label(preview.representativeRole, systemImage: "person.text.rectangle")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)

                    if let crd = preview.crdNumber, !crd.isEmpty {
                        HStack {
                            Label("CRD #\(crd)", systemImage: "checkmark.seal.fill")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("Verified")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.green)
                        }
                    }
                } footer: {
                    Text("Based on public records for \(preview.fullName).")
                }

                // Executive Summary
                Section("Executive Summary") {
                    Text(
                        preview.executiveSummary.isEmpty
                            ? "Verified during public profile lookup."
                            : preview.executiveSummary
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                // Key Facts
                if !preview.keyFacts.isEmpty {
                    Section("Key Facts") {
                        ForEach(preview.keyFacts, id: \.self) { fact in
                            Label {
                                Text(fact)
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Categories
                if !preview.categories.isEmpty {
                    Section("Categories") {
                        FlowLayout(spacing: 8) {
                            ForEach(preview.categories) { category in
                                Label(category.label, systemImage: category.icon)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Contact
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 0) {
                            Text("+1")
                                .foregroundStyle(.primary)
                                .padding(.trailing, 8)

                            TextField("8135551212", text: Binding(
                                get: { vm.phone },
                                set: vm.updatePhoneInput
                            ))
                            .focused($focusedField, equals: .phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                        }
                    }

                    if let phoneValidationMessage = vm.phoneValidationMessage {
                        Label(phoneValidationMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if !preview.websiteURL.isEmpty {
                        if let url = URL(string: preview.websiteURL) {
                            Link(destination: url) {
                                HStack {
                                    Text("Website")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(preview.websiteURL)
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                        .lineLimit(1)
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Contact")
                } footer: {
                    Text("Add your phone number to publish this profile on the deck.")
                }

                // Verified Sources
                if !preview.verifiedSources.isEmpty {
                    Section {
                        ForEach(preview.verifiedSources) { source in
                            if let url = URL(string: source.url) {
                                Link(destination: url) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundStyle(.green)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(source.platform)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            Text(source.label)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer(minLength: 0)

                                        Image(systemName: "arrow.up.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundStyle(.green)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(source.platform)
                                            .font(.subheadline)
                                        Text(source.label)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        Text("Verified Sources")
                    } footer: {
                        Text("\(preview.verifiedSources.count) source\(preview.verifiedSources.count == 1 ? "" : "s") confirmed this profile.")
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - No Match

    private var noMatchForm: some View {
        Form {
            Section {
                Label {
                    Text("We couldn't find a match")
                        .font(.headline)
                } icon: {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                }

                Text(vm.noMatchMessage ?? "No strong match was found in FINRA or SEC databases. This can happen with alternate spellings, maiden names, or very recent registrations.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section {
                    HStack {
                        Text("Searched")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(vm.query)
                    }
                }
            }

            if !vm.suggestedNames.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Did you mean?")
                            .font(.subheadline.weight(.semibold))

                        FlowLayout(spacing: 8) {
                            ForEach(vm.suggestedNames, id: \.self) { name in
                                Button {
                                    Task { await vm.selectSuggestion(name) }
                                } label: {
                                    Text(name)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Section {
                Text("Try your full legal name, or the exact firm name from your BrokerCheck listing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Error

    private var errorForm: some View {
        Form {
            Section {
                Label {
                    Text("Lookup temporarily unavailable")
                        .font(.headline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                }

                Text(vm.errorStateMessage ?? "Our research engine is briefly offline. This doesn't affect any data already saved — just try again in a moment.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section {
                    HStack {
                        Text("Searched for")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(vm.query)
                    }
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("HushhLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(spacing: 8) {
                Text(vm.loadingTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(vm.loadingSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ProgressView()
                .controlSize(.regular)

            if !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Searching for \(vm.query)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            if vm.phase == .preview {
                Button("Search Again") {
                    focusedField = nil
                    vm.searchAgain()
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
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
                HStack(spacing: 8) {
                    if vm.isBusy {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryActionTitle)
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(primaryActionDisabled)
            .opacity(primaryActionDisabled ? 0.45 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(.bar)
    }
}

// MARK: - Preview Avatar

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
                Color(.systemGray5)
                    .overlay(
                        Text(initials)
                            .font(.title3.bold())
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Previews

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
