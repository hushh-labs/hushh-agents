import Foundation
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case profile
        case presence

        var index: Int { rawValue + 1 }

        var title: String {
            switch self {
            case .profile:
                return "Build Your RIA Profile"
            case .presence:
                return "Go Discoverable"
            }
        }

        var subtitle: String {
            switch self {
            case .profile:
                return "Start with the identity and expertise other RIAs should see first."
            case .presence:
                return "Add the contact and visibility details that make your profile ready for the deck."
            }
        }
    }

    struct ChoiceOption: Identifiable {
        let id: String
        let label: String
        let icon: String
    }

    @Published var step: Step = .profile
    @Published var businessName = ""
    @Published var representativeName = ""
    @Published var representativeRole = ""
    @Published var specialties = ""
    @Published var selectedCategories: Set<String> = []
    @Published var zipCode = ""
    @Published var phone = ""
    @Published var websiteURL = ""
    @Published var selectedPhotoData: Data?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let userService = UserService()
    private let imageUploadService = ProfileImageUploadService()
    private let zipLocationResolver = ZipLocationResolver()
    private var didLoadInitialState = false
    private var existingProfile: HushhAgentProfile?

    var isProfileStepValid: Bool {
        !trimmed(businessName).isEmpty &&
        !trimmed(representativeName).isEmpty &&
        !trimmed(representativeRole).isEmpty &&
        !selectedCategories.isEmpty
    }

    var isPresenceStepValid: Bool {
        !trimmed(specialties).isEmpty &&
        !trimmed(zipCode).isEmpty &&
        normalizedPhoneDigits(from: phone).count == 10 &&
        hasPhoto
    }

    var primaryButtonTitle: String {
        switch step {
        case .profile:
            return "Continue"
        case .presence:
            return isLoading ? "Publishing..." : "Start Discovering"
        }
    }

    var secondaryButtonTitle: String? {
        step == .presence ? "Back" : nil
    }

    var progressValue: Double {
        Double(step.index) / Double(Step.allCases.count)
    }

    static let availableCategories: [ChoiceOption] = [
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

        representativeName = currentUser?.fullName ?? representativeName

        guard let userId else { return }

        if let existingProfile = try? await userService.fetchAgentProfile(userId: userId) {
            self.existingProfile = existingProfile
            apply(profile: existingProfile)
        }
    }

    func setSelectedPhotoData(_ data: Data?) {
        guard let data else {
            selectedPhotoData = nil
            return
        }

        guard let image = UIImage(data: data) else {
            errorMessage = "That photo format isn't supported. Please choose another image."
            return
        }

        selectedPhotoData = image.jpegData(compressionQuality: 0.84) ?? data
    }

    func toggleCategory(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.remove(categoryId)
        } else {
            selectedCategories.insert(categoryId)
        }
    }

    func goToNextStep() {
        guard isProfileStepValid else { return }
        step = .presence
    }

    func goBack() {
        step = .profile
    }

    func updatePhoneInput(_ value: String) {
        phone = normalizedPhoneDigits(from: value)
    }

    func submit(userId: UUID) async throws -> HushhAgentProfile {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let submitStartedAt = Date()
        let normalizedZip = trimmed(zipCode)
        let fallbackLocation = zipFallbackLocation(for: normalizedZip)

        logPublish(
            "Submit started for user \(userId.uuidString.lowercased()) with zip \(normalizedZip.isEmpty ? "<empty>" : normalizedZip)"
        )

        let uploadedPhotoURL: String?
        do {
            let uploadStartedAt = Date()
            let uploadPath = ProfileImageUploadService.primaryPhotoPath(for: userId)
            logPublish("Photo upload path: \(uploadPath)")
            uploadedPhotoURL = try await uploadPhotoIfNeeded(userId: userId)
            logPublish("Photo stage completed in \(durationString(since: uploadStartedAt))")
        } catch {
            logPublish("Photo upload failed after \(durationString(since: submitStartedAt)): \(error.localizedDescription)")
            errorMessage = "Your profile photo couldn't be uploaded right now. Please try again in a moment."
            throw error
        }

        let profile = buildProfile(
            userId: userId,
            resolvedLocation: fallbackLocation,
            uploadedPhotoURL: uploadedPhotoURL
        )

        let savedProfile: HushhAgentProfile
        do {
            let saveStartedAt = Date()
            savedProfile = try await userService.saveAgentProfile(profile)
            existingProfile = savedProfile
            logPublish("Profile save completed in \(durationString(since: saveStartedAt))")
        } catch {
            logPublish("Profile save failed after \(durationString(since: submitStartedAt)): \(error.localizedDescription)")
            errorMessage = "Your RIA profile couldn't be saved right now. Please try again in a moment."
            throw error
        }

        do {
            let accountStartedAt = Date()
            try await userService.updateUserAccount(
                userId: userId,
                fullName: trimmed(representativeName),
                phone: normalizedPhoneDigits(from: phone).nilIfEmpty,
                step: "complete",
                profileVisibility: "discoverable",
                discoveryEnabled: true
            )
            logPublish("Account update completed in \(durationString(since: accountStartedAt))")
        } catch {
            logPublish("Account completion failed after \(durationString(since: submitStartedAt)): \(error.localizedDescription)")
            errorMessage = "Your profile was saved, but we couldn't finish account setup right now. Please try again."
            throw error
        }

        scheduleLocationBackfillIfNeeded(userId: userId, zip: normalizedZip)
        logPublish("Submit finished in \(durationString(since: submitStartedAt))")

        return savedProfile
    }

    private func buildProfile(
        userId: UUID,
        resolvedLocation: ResolvedZipLocation,
        uploadedPhotoURL: String?
    ) -> HushhAgentProfile {
        let base = existingProfile ?? HushhAgentProfile.draft(
            for: userId,
            fullName: representativeName,
            email: nil
        )

        let orderedCategories = Self.availableCategories.map(\.id).filter(selectedCategories.contains)
        let normalizedWebsite = normalizedWebsiteURL
        let resolvedPhoto = uploadedPhotoURL ?? existingPhotoURL
        let normalizedPhone = normalizedPhoneDigits(from: phone)

        return HushhAgentProfile(
            id: base.id,
            userId: userId,
            catalogAgentId: base.catalogAgentId,
            businessName: trimmed(businessName),
            alias: base.alias,
            source: base.source,
            categories: orderedCategories,
            services: orderedCategories.map { self.goalToService($0) },
            specialties: trimmed(specialties),
            history: base.history,
            representativeName: trimmed(representativeName),
            representativeRole: trimmed(representativeRole),
            representativeBio: base.representativeBio,
            representativePhotoURL: resolvedPhoto,
            phone: normalizedPhone,
            formattedPhone: formattedPhoneNumber(from: normalizedPhone),
            websiteURL: normalizedWebsite,
            address1: base.address1,
            address2: base.address2,
            address3: base.address3,
            city: resolvedLocation.city,
            state: resolvedLocation.state,
            zip: resolvedLocation.zip,
            country: base.country,
            latitude: base.latitude,
            longitude: base.longitude,
            formattedAddress: resolvedLocation.formattedAddress,
            shortAddress: resolvedLocation.shortAddress,
            averageRating: base.averageRating,
            roundedRating: base.roundedRating,
            reviewCount: base.reviewCount,
            primaryPhotoURL: resolvedPhoto,
            photoCount: max(base.photoCount, resolvedPhoto == nil ? 0 : 1),
            photoList: resolvedPhoto.map { [AgentPhoto(id: nil, url: $0, thumbnailUrl: nil, width: nil, height: nil, caption: nil)] } ?? [],
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
            businessURL: normalizedWebsite,
            shareURL: base.shareURL,
            profileStatus: "discoverable",
            discoveryEnabled: true,
            updatedAt: nil
        )
    }

    private func apply(profile: HushhAgentProfile) {
        businessName = profile.businessName
        representativeName = profile.representativeName
        representativeRole = profile.representativeRole
        specialties = profile.specialties
        selectedCategories = Set(profile.categories)
        zipCode = profile.zip
        phone = normalizedPhoneDigits(from: profile.phone.isEmpty ? profile.formattedPhone : profile.phone)
        websiteURL = profile.websiteURL
    }

    var selectedPhotoPreviewImage: UIImage? {
        guard let selectedPhotoData else { return nil }
        return UIImage(data: selectedPhotoData)
    }

    var existingPhotoURL: String? {
        existingProfile?.displayPhotoURLString
    }

    var hasPhoto: Bool {
        selectedPhotoData != nil || existingPhotoURL != nil
    }

    private var normalizedWebsiteURL: String {
        let website = trimmed(websiteURL)
        guard !website.isEmpty else { return "" }
        if website.hasPrefix("http://") || website.hasPrefix("https://") {
            return website
        }
        return "https://\(website)"
    }

    private func uploadPhotoIfNeeded(userId: UUID) async throws -> String? {
        guard let selectedPhotoData else {
            logPublish("No new photo upload required")
            return nil
        }
        return try await imageUploadService.uploadPrimaryPhoto(data: selectedPhotoData, userId: userId)
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

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func zipFallbackLocation(for zip: String) -> ResolvedZipLocation {
        ResolvedZipLocation(
            city: "",
            state: "",
            zip: zip,
            formattedAddress: zip,
            shortAddress: zip
        )
    }

    private func normalizedPhoneDigits(from value: String) -> String {
        let digits = value.filter(\.isNumber)
        return String(digits.prefix(10))
    }

    private func formattedPhoneNumber(from digits: String) -> String {
        guard digits.count == 10 else {
            return digits
        }

        let areaCode = digits.prefix(3)
        let exchange = digits.dropFirst(3).prefix(3)
        let lineNumber = digits.dropFirst(6)
        return "(\(areaCode)) \(exchange)-\(lineNumber)"
    }

    private func scheduleLocationBackfillIfNeeded(userId: UUID, zip: String) {
        guard !zip.isEmpty else { return }

        Task.detached(priority: .utility) {
            let resolver = ZipLocationResolver()
            let userService = UserService()
            let geocodeStartedAt = Date()
            let userKey = userId.uuidString.lowercased()

            print("[Onboarding] Location enrichment started for user \(userKey) with zip \(zip)")
            let resolvedLocation = await resolver.resolve(zip: zip)
            print(
                "[Onboarding] Location enrichment finished in \(Self.durationStringStatic(since: geocodeStartedAt))"
            )

            let hasResolvedLocation = !resolvedLocation.city.isEmpty || !resolvedLocation.state.isEmpty
            guard hasResolvedLocation else {
                print("[Onboarding] Location enrichment skipped patch because geocoder returned ZIP-only fallback")
                return
            }

            let patchStartedAt = Date()
            do {
                _ = try await userService.updateAgentProfileLocation(
                    userId: userId,
                    location: resolvedLocation
                )
                print(
                    "[Onboarding] Location patch saved in \(Self.durationStringStatic(since: patchStartedAt))"
                )
            } catch {
                print(
                    "[Onboarding] Location patch failed after \(Self.durationStringStatic(since: patchStartedAt)): \(error.localizedDescription)"
                )
            }
        }
    }

    private func logPublish(_ message: String) {
        print("[Onboarding] \(message)")
    }

    private func durationString(since startDate: Date) -> String {
        Self.durationStringStatic(since: startDate)
    }

    nonisolated private static func durationStringStatic(since startDate: Date) -> String {
        String(format: "%.2fs", Date().timeIntervalSince(startDate))
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
