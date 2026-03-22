import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Phase: Equatable, Sendable {
        case nameEntry
        case loading
        case preview
        case noMatch
        case error
    }

    struct ChoiceOption: Identifiable, Equatable, Sendable {
        let id: String
        let label: String
        let icon: String
    }

    struct VerifiedSource: Equatable, Identifiable, Sendable {
        let id: String
        let platform: String
        let label: String
        let url: String
    }

    struct PreviewContent: Equatable, Sendable {
        let submittedQuery: String
        let fullName: String
        let firmName: String
        let locationLine: String
        let executiveSummary: String
        let specialties: String
        let representativeRole: String
        let categories: [ChoiceOption]
        let imageURL: String?
        let websiteURL: String
        let businessURL: String
        let history: String
        let verifiedSourcesCount: Int
        let keyFacts: [String]
        let crdNumber: String?
        let verifiedSources: [VerifiedSource]

        var initials: String {
            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return "HA" }

            let parts = trimmedName.split(separator: " ")
            if parts.count >= 2 {
                return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
            }

            return String(trimmedName.prefix(2)).uppercased()
        }
    }

    private struct LoadingMessage: Sendable {
        let title: String
        let subtitle: String
    }

    private struct ParsedLocation: Sendable {
        let city: String
        let state: String
        let formattedAddress: String
        let shortAddress: String
    }

    @Published var phase: Phase = .nameEntry
    @Published var query = ""
    @Published var phone = ""
    @Published private(set) var previewContent: PreviewContent?
    @Published private(set) var loadingTitle = "Verifying your public records"
    @Published private(set) var loadingSubtitle = "Checking FINRA and SEC sources before building your dossier."
    @Published var queryValidationMessage: String?
    @Published var phoneValidationMessage: String?
    @Published var noMatchMessage: String?
    @Published var errorStateMessage: String?
    @Published var alertMessage: String?
    @Published var isSaving = false

    private let userService: UserService
    private let intelligenceService: RIAIntelligenceServicing
    private var didLoadInitialState = false
    private var existingProfile: HushhAgentProfile?
    private var currentUser: AppUser?
    private var loadingTask: Task<Void, Never>?

    init(
        userService: UserService = UserService(),
        intelligenceService: RIAIntelligenceServicing = RIAIntelligenceService()
    ) {
        self.userService = userService
        self.intelligenceService = intelligenceService
    }

    var isBusy: Bool {
        phase == .loading || isSaving
    }

    var canSubmitQuery: Bool {
        !trimmed(query).isEmpty && !isBusy
    }

    var canSavePreview: Bool {
        normalizedPhoneDigits(from: phone).count == 10 && !isBusy && previewContent != nil
    }

    nonisolated static let availableCategories: [ChoiceOption] = [
        .init(id: "wealth_management", label: "Wealth Management", icon: "dollarsign.circle"),
        .init(id: "financial_planning", label: "Financial Planning", icon: "chart.bar"),
        .init(id: "investment_advisory", label: "Investment Advisory", icon: "chart.line.uptrend.xyaxis"),
        .init(id: "retirement_planning", label: "Retirement Planning", icon: "building.columns"),
        .init(id: "tax_planning", label: "Tax Planning", icon: "doc.text"),
        .init(id: "insurance", label: "Insurance", icon: "shield.lefthalf.filled")
    ]

    func loadInitialState(userId: UUID?, currentUser: AppUser?) async {
        guard !didLoadInitialState else { return }
        didLoadInitialState = true
        self.currentUser = currentUser

        guard let userId else {
            phone = normalizedPhoneDigits(from: currentUser?.phone ?? "")
            return
        }

        if let existingProfile = try? await userService.fetchAgentProfile(userId: userId) {
            self.existingProfile = existingProfile
            phone = normalizedPhoneDigits(
                from: existingProfile.phone.isEmpty ? existingProfile.formattedPhone : existingProfile.phone
            )
        } else {
            phone = preferredPrefilledPhone()
        }
    }

    func updateQuery(_ value: String) {
        query = value
        queryValidationMessage = nil
    }

    func updatePhoneInput(_ value: String) {
        phone = normalizedPhoneDigits(from: value)
        phoneValidationMessage = nil
    }

    func startLookup() async {
        let submittedQuery = trimmed(query)
        guard !submittedQuery.isEmpty else {
            queryValidationMessage = RIAIntelligenceLookupError.blankQuery.errorDescription
            return
        }

        queryValidationMessage = nil
        phoneValidationMessage = nil
        noMatchMessage = nil
        errorStateMessage = nil
        previewContent = nil
        phase = .loading
        beginLoadingAnimation()

        do {
            let dossier = try await intelligenceService.lookupProfile(query: submittedQuery)
            stopLoadingAnimation()
            previewContent = buildPreviewContent(dossier: dossier, submittedQuery: submittedQuery)
            if phone.isEmpty {
                phone = preferredPrefilledPhone()
            }
            phase = .preview
        } catch let error as RIAIntelligenceLookupError {
            stopLoadingAnimation()
            handleLookupError(error)
        } catch {
            stopLoadingAnimation()
            handleLookupError(.networkFailure(message: error.localizedDescription))
        }
    }

    func searchAgain() {
        stopLoadingAnimation()
        phase = .nameEntry
        previewContent = nil
        queryValidationMessage = nil
        phoneValidationMessage = nil
        noMatchMessage = nil
        errorStateMessage = nil
    }

    func submit(userId: UUID) async throws -> HushhAgentProfile {
        guard let previewContent else {
            throw RIAIntelligenceLookupError.upstreamFailure(message: "No dossier preview is available to save.")
        }

        let normalizedPhone = normalizedPhoneDigits(from: phone)
        guard normalizedPhone.count == 10 else {
            phoneValidationMessage = "Enter a 10-digit phone number to continue."
            throw RIAIntelligenceLookupError.networkFailure(message: "Phone number is required.")
        }

        isSaving = true
        defer { isSaving = false }

        let profile = buildProfile(userId: userId, previewContent: previewContent, normalizedPhone: normalizedPhone)

        do {
            let savedProfile = try await userService.saveAgentProfile(profile)
            existingProfile = savedProfile

            try await userService.updateUserAccount(
                userId: userId,
                fullName: savedProfile.representativeName.nilIfEmpty,
                phone: normalizedPhone,
                step: "complete",
                profileVisibility: "discoverable",
                discoveryEnabled: true
            )

            return savedProfile
        } catch {
            alertMessage = "We couldn't publish your RIA profile right now. Please try again."
            throw error
        }
    }

    private func handleLookupError(_ error: RIAIntelligenceLookupError) {
        switch error {
        case .blankQuery:
            phase = .nameEntry
            queryValidationMessage = error.errorDescription
        case .noMatch(let reason):
            phase = .noMatch
            noMatchMessage = reason ?? error.errorDescription
        case .upstreamFailure, .networkFailure:
            phase = .error
            errorStateMessage = error.errorDescription
        }
    }

    private func beginLoadingAnimation() {
        let messages = Self.loadingMessages
        loadingTitle = messages[0].title
        loadingSubtitle = messages[0].subtitle
        loadingTask?.cancel()

        loadingTask = Task { [weak self] in
            guard let self else { return }
            var index = 0

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                index = (index + 1) % messages.count
                loadingTitle = messages[index].title
                loadingSubtitle = messages[index].subtitle
            }
        }
    }

    private func stopLoadingAnimation() {
        loadingTask?.cancel()
        loadingTask = nil
    }

    private func buildPreviewContent(
        dossier: RIAProfileDossier,
        submittedQuery: String
    ) -> PreviewContent {
        let fullName = firstNonEmpty(dossier.subject.fullName, submittedQuery) ?? submittedQuery
        let executiveSummary = cleaned(dossier.executiveSummary)
            ?? cleaned(existingProfile?.representativeBio)
            ?? ""
        let topFacts = dossier.keyFacts
            .compactMap { cleaned($0.fact) }
            .filter { !$0.isEmpty }
        let specialties = firstSentence(from: executiveSummary)
            ?? topFacts.first
            ?? cleaned(existingProfile?.specialties)
            ?? ""
        let categories = deriveCategories(from: dossier)
        let role = deriveRepresentativeRole(from: dossier)
        let imageURL = preferredImageURL(from: dossier) ?? rawExistingPhotoURL
        let websiteURL = preferredWebsiteURL(from: dossier) ?? cleaned(existingProfile?.websiteURL) ?? ""
        let businessURL = firstNonEmpty(preferredBusinessURL(from: dossier), websiteURL, cleaned(existingProfile?.businessURL)) ?? ""
        let history = buildHistory(from: topFacts, executiveSummary: executiveSummary, existingHistory: existingProfile?.history)
        let locationLine = cleaned(dossier.subject.location) ?? cleaned(existingProfile?.formattedAddress) ?? ""

        return PreviewContent(
            submittedQuery: submittedQuery,
            fullName: fullName,
            firmName: firstNonEmpty(cleaned(dossier.subject.currentFirm), cleaned(existingProfile?.businessName)) ?? "",
            locationLine: locationLine,
            executiveSummary: executiveSummary,
            specialties: specialties,
            representativeRole: role,
            categories: categories,
            imageURL: imageURL,
            websiteURL: websiteURL,
            businessURL: businessURL,
            history: history,
            verifiedSourcesCount: dossier.verifiedProfiles.count,
            keyFacts: Array(topFacts.prefix(3)),
            crdNumber: cleaned(dossier.subject.crdNumber),
            verifiedSources: dossier.verifiedProfiles.compactMap { vp in
                guard let platform = cleaned(vp.platform),
                      let label = cleaned(vp.label),
                      let url = cleaned(vp.url) else { return nil }
                return VerifiedSource(id: vp.id, platform: platform, label: label, url: url)
            }
        )
    }

    private func buildProfile(
        userId: UUID,
        previewContent: PreviewContent,
        normalizedPhone: String
    ) -> HushhAgentProfile {
        let base = existingProfile ?? HushhAgentProfile.draft(
            for: userId,
            fullName: previewContent.fullName,
            email: currentUser?.email
        )
        let parsedLocation = parseLocation(from: previewContent.locationLine)
        let categories = previewContent.categories.isEmpty
            ? (base.categories.isEmpty ? ["investment_advisory"] : base.categories)
            : previewContent.categories.map(\.id)
        let websiteURL = firstNonEmpty(previewContent.websiteURL, cleaned(base.websiteURL), cleaned(base.businessURL)) ?? ""
        let businessURL = firstNonEmpty(previewContent.businessURL, websiteURL, cleaned(base.businessURL)) ?? ""
        let photoURL = firstNonEmpty(previewContent.imageURL, rawExistingPhotoURL)
        let formattedPhone = formattedPhoneNumber(from: normalizedPhone)

        return HushhAgentProfile(
            id: base.id,
            userId: userId,
            catalogAgentId: base.catalogAgentId,
            businessName: firstNonEmpty(previewContent.firmName, cleaned(base.businessName)) ?? "",
            alias: base.alias,
            source: "ria_intelligence_api",
            categories: categories,
            services: categories.map(goalToService),
            specialties: firstNonEmpty(previewContent.specialties, cleaned(base.specialties)) ?? "",
            history: firstNonEmpty(previewContent.history, cleaned(base.history)) ?? "",
            representativeName: firstNonEmpty(previewContent.fullName, cleaned(base.representativeName)) ?? previewContent.submittedQuery,
            representativeRole: firstNonEmpty(previewContent.representativeRole, cleaned(base.representativeRole), "Advisor") ?? "Advisor",
            representativeBio: firstNonEmpty(previewContent.executiveSummary, cleaned(base.representativeBio)) ?? "",
            representativePhotoURL: photoURL,
            phone: normalizedPhone,
            formattedPhone: formattedPhone,
            websiteURL: websiteURL,
            address1: base.address1,
            address2: base.address2,
            address3: base.address3,
            city: firstNonEmpty(parsedLocation?.city, cleaned(base.city)) ?? "",
            state: firstNonEmpty(parsedLocation?.state, cleaned(base.state)) ?? "",
            zip: base.zip,
            country: cleaned(base.country) ?? "US",
            latitude: base.latitude,
            longitude: base.longitude,
            formattedAddress: firstNonEmpty(parsedLocation?.formattedAddress, cleaned(base.formattedAddress)) ?? "",
            shortAddress: firstNonEmpty(parsedLocation?.shortAddress, cleaned(base.shortAddress)) ?? "",
            averageRating: base.averageRating,
            roundedRating: base.roundedRating,
            reviewCount: base.reviewCount,
            primaryPhotoURL: photoURL,
            photoCount: max(base.photoCount, photoURL == nil ? 0 : 1),
            photoList: photoURL.map {
                [AgentPhoto(id: nil, url: $0, thumbnailUrl: nil, width: nil, height: nil, caption: nil)]
            } ?? base.photoList,
            isClosed: base.isClosed,
            isChain: base.isChain,
            isYelpGuaranteed: base.isYelpGuaranteed,
            hours: base.hours,
            yearEstablished: base.yearEstablished,
            messagingEnabled: true,
            messagingType: "direct",
            messagingDisplayText: "Open conversation",
            messagingResponseTime: base.messagingResponseTime,
            messagingReplyRate: base.messagingReplyRate,
            annotations: base.annotations,
            businessURL: businessURL,
            shareURL: base.shareURL,
            profileStatus: "discoverable",
            discoveryEnabled: true,
            updatedAt: nil
        )
    }

    private var rawExistingPhotoURL: String? {
        firstNonEmpty(cleaned(existingProfile?.primaryPhotoURL), cleaned(existingProfile?.representativePhotoURL))
    }

    private func deriveCategories(from dossier: RIAProfileDossier) -> [ChoiceOption] {
        let haystack = [
            cleaned(dossier.executiveSummary),
            cleaned(dossier.subject.currentFirm),
            dossier.keyFacts.compactMap { cleaned($0.fact) }.joined(separator: " "),
            dossier.verifiedProfiles.compactMap { cleaned($0.label) }.joined(separator: " ")
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let matches: [(String, [String])] = [
            ("wealth_management", ["wealth", "portfolio", "assets"]),
            ("financial_planning", ["planning", "planner"]),
            ("investment_advisory", ["investment", "advisory", "securities"]),
            ("retirement_planning", ["retirement", "401k", "pension"]),
            ("tax_planning", ["tax", "cpa", "finop"]),
            ("insurance", ["insurance", "annuity", "life insurance"])
        ]

        let matchedIDs = matches.compactMap { categoryId, keywords in
            keywords.contains { haystack.contains($0) } ? categoryId : nil
        }

        let orderedIDs = matchedIDs.isEmpty ? ["investment_advisory"] : matchedIDs
        return Self.availableCategories.filter { orderedIDs.contains($0.id) }
    }

    private func deriveRepresentativeRole(from dossier: RIAProfileDossier) -> String {
        let haystack = [
            cleaned(dossier.executiveSummary),
            dossier.keyFacts.compactMap { cleaned($0.fact) }.joined(separator: " ")
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .lowercased()

        let roles: [(String, [String])] = [
            ("Founder", ["founder"]),
            ("Managing Partner", ["managing partner"]),
            ("Partner", ["partner"]),
            ("President", ["president"]),
            ("CEO", ["ceo", "chief executive officer"]),
            ("CFO", ["cfo", "chief financial officer"]),
            ("FINOP", ["finop"]),
            ("Advisor", ["advisor", "adviser"])
        ]

        for (label, keywords) in roles where keywords.contains(where: haystack.contains) {
            return label
        }

        return "Advisor"
    }

    private func preferredImageURL(from dossier: RIAProfileDossier) -> String? {
        dossier.publicImages
            .compactMap { image -> (url: String, score: Int)? in
                guard
                    let imageURL = cleaned(image.imageURL),
                    isDisplayableImageURL(imageURL, sourcePageURL: image.sourcePageURL)
                else {
                    return nil
                }

                return (imageURL, imagePreferenceScore(for: image, imageURL: imageURL))
            }
            .max { $0.score < $1.score }?
            .url
    }

    private func preferredWebsiteURL(from dossier: RIAProfileDossier) -> String? {
        preferredNonRegulatoryURL(
            dossier.verifiedProfiles.compactMap { cleaned($0.url) } +
            dossier.verifiedProfiles.compactMap { cleaned($0.sourceURL) } +
            dossier.keyFacts.compactMap { cleaned($0.sourceURL) } +
            dossier.publicImages.compactMap { cleaned($0.sourcePageURL) }
        )
    }

    private func preferredBusinessURL(from dossier: RIAProfileDossier) -> String? {
        preferredNonRegulatoryURL(
            dossier.publicImages.compactMap { cleaned($0.sourcePageURL) } +
            dossier.keyFacts.compactMap { cleaned($0.sourceURL) } +
            dossier.verifiedProfiles.compactMap { cleaned($0.sourceURL) }
        )
    }

    private func preferredNonRegulatoryURL(_ urls: [String]) -> String? {
        for rawValue in urls {
            guard
                let cleanedValue = cleaned(rawValue),
                let url = URL(string: cleanedValue),
                let host = url.host?.lowercased()
            else {
                continue
            }

            if Self.regulatoryHosts.contains(host) {
                continue
            }

            return cleanedValue
        }

        return nil
    }

    private func isDisplayableImageURL(_ rawValue: String, sourcePageURL: String?) -> Bool {
        guard
            let imageURL = URL(string: rawValue),
            let scheme = imageURL.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return false
        }

        let loweredPath = imageURL.path.lowercased()
        let webpageExtensions = [".html", ".htm", ".php", ".asp", ".aspx", ".jsp"]
        if webpageExtensions.contains(where: loweredPath.hasSuffix) {
            return false
        }

        guard let sourcePageURL = cleaned(sourcePageURL) else {
            return true
        }

        return normalizedURLComparisonKey(for: rawValue) != normalizedURLComparisonKey(for: sourcePageURL)
    }

    private func imagePreferenceScore(
        for image: RIAProfileDossier.PublicImage,
        imageURL: String
    ) -> Int {
        let kind = (image.kind ?? "").lowercased()
        let loweredURL = imageURL.lowercased()

        var score = 0
        if kind.contains("headshot") || kind.contains("portrait") || kind.contains("profile") {
            score += 60
        } else if kind.contains("banner") {
            score += 35
        } else if kind.contains("logo") {
            score += 20
        }

        if loweredURL.contains("/image/") || loweredURL.contains("image") {
            score += 15
        }

        let rasterExtensions = [".jpg", ".jpeg", ".png", ".webp", ".gif", ".heic", ".avif"]
        if rasterExtensions.contains(where: loweredURL.hasSuffix) {
            score += 20
        }

        if loweredURL.hasSuffix(".svg") {
            score -= 20
        }

        return score
    }

    private func normalizedURLComparisonKey(for rawValue: String) -> String {
        guard var components = URLComponents(string: rawValue.lowercased()) else {
            return rawValue.lowercased()
        }

        components.fragment = nil
        components.query = nil
        let normalizedPath = components.path.hasSuffix("/") && components.path.count > 1
            ? String(components.path.dropLast())
            : components.path
        components.path = normalizedPath

        return components.string ?? rawValue.lowercased()
    }

    private func buildHistory(
        from topFacts: [String],
        executiveSummary: String,
        existingHistory: String?
    ) -> String {
        let joinedFacts = Array(topFacts.prefix(3)).joined(separator: "\n\n")
        return firstNonEmpty(joinedFacts, executiveSummary, cleaned(existingHistory)) ?? ""
    }

    private func parseLocation(from rawLocation: String) -> ParsedLocation? {
        let trimmedLocation = trimmed(rawLocation)
        guard !trimmedLocation.isEmpty else { return nil }

        let parts = trimmedLocation
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let city = parts.first ?? ""
        let state = parts.count > 1 ? parts[1] : ""
        let shortAddress = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")

        return ParsedLocation(
            city: city,
            state: state,
            formattedAddress: trimmedLocation,
            shortAddress: shortAddress.isEmpty ? trimmedLocation : shortAddress
        )
    }

    private func goalToService(_ goal: String) -> String {
        switch goal {
        case "wealth_management":
            return "Wealth Management"
        case "financial_planning":
            return "Financial Planning"
        case "investment_advisory":
            return "Investment Advisory"
        case "retirement_planning":
            return "Retirement Planning"
        case "tax_planning":
            return "Tax Planning"
        case "insurance":
            return "Insurance"
        default:
            return goal.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func firstSentence(from text: String) -> String? {
        let cleanedText = trimmed(text)
        guard !cleanedText.isEmpty else { return nil }

        let separators = CharacterSet(charactersIn: ".!?")
        if let range = cleanedText.rangeOfCharacter(from: separators) {
            return trimmed(String(cleanedText[..<range.upperBound]))
        }

        return cleanedText
    }

    private func normalizedPhoneDigits(from value: String) -> String {
        let digits = value.filter(\.isNumber)
        return String(digits.prefix(10))
    }

    private func formattedPhoneNumber(from digits: String) -> String {
        guard digits.count == 10 else { return digits }

        let areaCode = digits.prefix(3)
        let exchange = digits.dropFirst(3).prefix(3)
        let lineNumber = digits.dropFirst(6)
        return "(\(areaCode)) \(exchange)-\(lineNumber)"
    }

    private func preferredPrefilledPhone() -> String {
        if let existingProfile, !existingProfile.phone.isEmpty {
            return normalizedPhoneDigits(from: existingProfile.phone)
        }

        if let existingProfile, !existingProfile.formattedPhone.isEmpty {
            return normalizedPhoneDigits(from: existingProfile.formattedPhone)
        }

        return normalizedPhoneDigits(from: currentUser?.phone ?? "")
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleaned(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = trimmed(value)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap { cleaned($0) }.first
    }

    nonisolated private static let loadingMessages: [LoadingMessage] = [
        LoadingMessage(
            title: "Verifying your public records",
            subtitle: "Checking FINRA and SEC sources before building your dossier."
        ),
        LoadingMessage(
            title: "Researching your dossier",
            subtitle: "Pulling together public profile signals and source-backed facts."
        ),
        LoadingMessage(
            title: "Selecting your best image",
            subtitle: "Ranking validated public images for the strongest deck preview."
        ),
        LoadingMessage(
            title: "Cross-referencing sources",
            subtitle: "Matching regulatory records with verified web data."
        ),
        LoadingMessage(
            title: "Building your profile",
            subtitle: "This deep research takes a moment — hang tight."
        ),
        LoadingMessage(
            title: "Almost there",
            subtitle: "Finalizing your dossier and validating images."
        ),
        LoadingMessage(
            title: "Still working on it",
            subtitle: "Deep lookups can take several minutes when fallback research kicks in."
        )
    ]

    nonisolated private static let regulatoryHosts: Set<String> = [
        "adviserinfo.sec.gov",
        "brokercheck.finra.org",
        "files.brokercheck.finra.org",
        "finra.org",
        "sec.gov",
        "www.finra.org",
        "www.sec.gov"
    ]
}

extension OnboardingViewModel {
    @MainActor
    static func previewViewModel(
        phase: Phase,
        query: String = "ANA ROUMENOVA CARTER",
        phone: String = "8135551212"
    ) -> OnboardingViewModel {
        let viewModel = OnboardingViewModel(
            userService: UserService(),
            intelligenceService: PreviewIntelligenceService()
        )
        viewModel.query = query
        viewModel.phone = phone
        viewModel.phase = phase

        switch phase {
        case .loading:
            viewModel.loadingTitle = Self.loadingMessages[1].title
            viewModel.loadingSubtitle = Self.loadingMessages[1].subtitle
        case .preview:
            viewModel.previewContent = PreviewIntelligenceService.samplePreview
        case .noMatch:
            viewModel.noMatchMessage = "We couldn't confidently match that name to FINRA or SEC records."
        case .error:
            viewModel.errorStateMessage = "The profile lookup service is temporarily unavailable."
        case .nameEntry:
            break
        }

        return viewModel
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct PreviewIntelligenceService: RIAIntelligenceServicing {
    func lookupProfile(query: String) async throws -> RIAProfileDossier {
        .init()
    }

    static let samplePreview = OnboardingViewModel.PreviewContent(
        submittedQuery: "Rogan and Associates",
        fullName: "ROGAN & ASSOCIATES, INC.",
        firmName: "Rogan & Associates, Inc.",
        locationLine: "Safety Harbor, FL",
        executiveSummary: "Rogan & Associates, Inc. (CRD 42762) is a Florida-based financial advisory firm and broker-dealer operating from Safety Harbor, FL. The firm is a member of FINRA and SIPC and offers both brokerage and registered investment adviser services. Michael G. Rogan serves as President and Founder; Edwin R. Foss is Chief Compliance Officer.",
        specialties: "Rogan & Associates, Inc. (CRD 42762) is a Florida-based financial advisory firm and broker-dealer.",
        representativeRole: "Founder",
        categories: OnboardingViewModel.availableCategories.filter {
            ["wealth_management", "financial_planning", "investment_advisory"].contains($0.id)
        },
        imageURL: nil,
        websiteURL: "https://roganfinancial.com/",
        businessURL: "https://roganfinancial.com/",
        history: "Firm legal name: Rogan & Associates, Inc. — CRD 42762.\n\nFirm address: 200 9th Avenue North, Suite 100, Safety Harbor, FL 34695; Phone (727) 712-3400.\n\nMichael G. Rogan is President & Founder; Edwin R. Foss is Chief Compliance Officer.",
        verifiedSourcesCount: 7,
        keyFacts: [
            "Firm legal name and CRD number: Rogan & Associates, Inc. — CRD 42762.",
            "Firm address and phone: 200 9th Avenue North, Suite 100, Safety Harbor, FL 34695; Phone (727) 712-3400.",
            "Firm is a member of FINRA and SIPC and provides both brokerage and investment advisory services."
        ],
        crdNumber: "42762",
        verifiedSources: [
            .init(id: "1", platform: "Company website", label: "Rogan & Associates – Financial Planning For Life", url: "https://roganfinancial.com/"),
            .init(id: "2", platform: "Form ADV / Disclosure Brochure", label: "Form ADV Part 2A — Disclosure Brochure", url: "https://roganfinancial.com/wp-content/uploads/2025/04/Form-ADV.Part-2A.Disclosure-Brochure.RA.04.2025.pdf"),
            .init(id: "3", platform: "Form CRS (SEC)", label: "Form CRS (Rogan & Associates, Inc.)", url: "https://reports.adviserinfo.sec.gov/crs/crs_42762.pdf"),
            .init(id: "4", platform: "FINRA BrokerCheck", label: "Firm Report — CRD 42762", url: "https://files.brokercheck.finra.org/firm/firm_42762.pdf"),
            .init(id: "5", platform: "FINRA BrokerCheck", label: "Michael G. Rogan — Individual Report", url: "https://files.brokercheck.finra.org/individual/individual_1503029.pdf"),
            .init(id: "6", platform: "FINRA BrokerCheck", label: "Edwin R. Foss — Individual Report", url: "https://files.brokercheck.finra.org/individual/individual_1334662.pdf"),
            .init(id: "7", platform: "Crunchbase", label: "Rogan & Associates — Company Profile", url: "https://www.crunchbase.com/organization/rogan-associates")
        ]
    )
}
