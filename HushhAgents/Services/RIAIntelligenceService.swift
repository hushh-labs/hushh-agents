import Foundation

protocol RIAIntelligenceServicing {
    func lookupProfile(query: String) async throws -> RIAProfileDossier
}

enum RIAIntelligenceLookupError: LocalizedError, Equatable {
    case blankQuery
    case noMatch(reason: String?)
    case upstreamFailure(message: String?)
    case networkFailure(message: String?)

    var errorDescription: String? {
        switch self {
        case .blankQuery:
            return "Enter a name to look up your public RIA profile."
        case .noMatch(let reason):
            return reason ?? "We couldn't confidently match that name to FINRA or SEC records."
        case .upstreamFailure(let message):
            return message ?? "The profile lookup service is temporarily unavailable."
        case .networkFailure(let message):
            return message ?? "We couldn't reach the profile lookup service right now."
        }
    }
}

final class RIAIntelligenceService: RIAIntelligenceServicing {
    private static let defaultTimeout: TimeInterval = 360

    private struct LookupRequest: Encodable {
        let query: String
    }

    private struct ErrorResponse: Decodable {
        let detail: String?
        let message: String?
        let error: String?

        var resolvedMessage: String? {
            detail ?? message ?? error
        }
    }

    private struct Configuration {
        let endpointURL: URL
        let timeout: TimeInterval

        init(bundle: Bundle = .main) throws {
            let rawBaseURL = (bundle.object(forInfoDictionaryKey: "RIA_INTELLIGENCE_API_BASE_URL") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard let baseURL = URL(string: rawBaseURL), !rawBaseURL.isEmpty else {
                throw RIAIntelligenceLookupError.networkFailure(
                    message: "Profile lookup is not configured on this build."
                )
            }

            let timeoutValue = bundle.object(forInfoDictionaryKey: "RIA_INTELLIGENCE_API_TIMEOUT_SECONDS")
            let timeout: TimeInterval
            if let rawString = timeoutValue as? String, let parsed = TimeInterval(rawString), parsed > 0 {
                timeout = parsed
            } else if let rawNumber = timeoutValue as? NSNumber, rawNumber.doubleValue > 0 {
                timeout = rawNumber.doubleValue
            } else {
                timeout = RIAIntelligenceService.defaultTimeout
            }

            endpointURL = Self.endpointURL(from: baseURL)
            self.timeout = timeout
        }

        private static func endpointURL(from baseURL: URL) -> URL {
            let endpointPath = "/v1/ria/profile"
            if baseURL.path.hasSuffix(endpointPath) {
                return baseURL
            }

            let normalizedPath = baseURL.path.hasSuffix("/") ? String(baseURL.path.dropLast()) : baseURL.path
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.path = normalizedPath + endpointPath
            return components?.url ?? baseURL.appendingPathComponent("v1/ria/profile")
        }
    }

    private let session: URLSession
    private let bundle: Bundle

    init(session: URLSession? = nil, bundle: Bundle = .main) {
        self.bundle = bundle
        self.session = session ?? Self.makeSession(timeout: Self.resolvedTimeout(bundle: bundle))
    }

    func lookupProfile(query: String) async throws -> RIAProfileDossier {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw RIAIntelligenceLookupError.blankQuery
        }

        let config = try Configuration(bundle: bundle)

        var request = URLRequest(url: config.endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = config.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LookupRequest(query: trimmedQuery))

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RIAIntelligenceLookupError.networkFailure(message: "Invalid response from profile lookup.")
            }

            switch httpResponse.statusCode {
            case 200:
                let dossier = try decodeLookupResponse(from: data, submittedQuery: trimmedQuery)
                if dossier.noConfidentMatch {
                    throw RIAIntelligenceLookupError.noMatch(reason: dossier.unverifiedOrNotFound.first)
                }
                return dossier
            case 400, 422:
                throw RIAIntelligenceLookupError.blankQuery
            case 502:
                throw RIAIntelligenceLookupError.upstreamFailure(
                    message: decodeErrorMessage(from: data) ?? "The profile lookup could not build a usable dossier."
                )
            case 500...599:
                throw RIAIntelligenceLookupError.upstreamFailure(message: decodeErrorMessage(from: data))
            default:
                throw RIAIntelligenceLookupError.networkFailure(message: decodeErrorMessage(from: data))
            }
        } catch let error as RIAIntelligenceLookupError {
            throw error
        } catch is DecodingError {
            throw RIAIntelligenceLookupError.upstreamFailure(message: "We received an unreadable dossier response.")
        } catch let error as URLError {
            throw RIAIntelligenceLookupError.networkFailure(message: friendlyMessage(for: error))
        } catch {
            throw RIAIntelligenceLookupError.networkFailure(message: error.localizedDescription)
        }
    }

    private func decodeLookupResponse(from data: Data, submittedQuery: String) throws -> RIAProfileDossier {
        let decoder = JSONDecoder()

        if let dossier = try? decoder.decode(RIAProfileDossier.self, from: data) {
            return dossier
        }

        if let legacyResponse = try? decoder.decode(LegacyLookupResponse.self, from: data) {
            if legacyResponse.success == false, legacyResponse.profile == nil {
                throw RIAIntelligenceLookupError.upstreamFailure(
                    message: legacyResponse.warnings.first ?? "The profile lookup service returned an unsuccessful response."
                )
            }

            return legacyResponse.asDossier(submittedQuery: submittedQuery)
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Unsupported profile lookup response shape.")
        )
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        return (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.resolvedMessage
    }

    private func friendlyMessage(for error: URLError) -> String {
        switch error.code {
        case .timedOut:
            return "The profile lookup took longer than expected. Some deep research requests can take a few minutes, so please try again."
        case .notConnectedToInternet, .networkConnectionLost:
            return "You're offline right now. Please reconnect and try again."
        default:
            return error.localizedDescription
        }
    }

    private static func resolvedTimeout(bundle: Bundle) -> TimeInterval {
        (try? Configuration(bundle: bundle).timeout) ?? defaultTimeout
    }

    private static func makeSession(timeout: TimeInterval) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        return URLSession(configuration: configuration)
    }
}

private struct LegacyLookupResponse: Decodable {
    struct Profile: Decodable {
        let existsOnFinra: Bool?
        let imageUrl: String?
        let crdNumber: String?
        let secNumber: String?
        let fullName: String?
        let otherNames: [String]
        let currentFirm: String?
        let location: String?
        let mainAddress: String?
        let phone: String?
        let regulatedBy: String?
        let yearsOfExperience: String?
        let linkedinUrl: String?
        let twitterUrl: String?
        let facebookUrl: String?
        let websiteUrl: String?
        let bio: String?
        let examsPassed: [String]
        let stateLicenses: [String]
        let previousFirms: [String]
        let servicesOffered: [String]
        let clientTypes: [String]
        let specialties: [String]
        let reasonIfNotExists: String?

        enum CodingKeys: String, CodingKey {
            case existsOnFinra
            case imageUrl
            case crdNumber
            case secNumber
            case fullName
            case otherNames
            case currentFirm
            case location
            case mainAddress
            case phone
            case regulatedBy
            case yearsOfExperience
            case linkedinUrl
            case twitterUrl
            case facebookUrl
            case websiteUrl
            case bio
            case examsPassed
            case stateLicenses
            case previousFirms
            case servicesOffered
            case clientTypes
            case specialties
            case reasonIfNotExists
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            existsOnFinra = try container.decodeIfPresent(Bool.self, forKey: .existsOnFinra)
            imageUrl = try container.decodeLossyStringIfPresent(forKey: .imageUrl)
            crdNumber = try container.decodeLossyStringIfPresent(forKey: .crdNumber)
            secNumber = try container.decodeLossyStringIfPresent(forKey: .secNumber)
            fullName = try container.decodeLossyStringIfPresent(forKey: .fullName)
            otherNames = try container.decodeLossyStringArray(forKey: .otherNames)
            currentFirm = try container.decodeLossyStringIfPresent(forKey: .currentFirm)
            location = try container.decodeLossyStringIfPresent(forKey: .location)
            mainAddress = try container.decodeLossyStringIfPresent(forKey: .mainAddress)
            phone = try container.decodeLossyStringIfPresent(forKey: .phone)
            regulatedBy = try container.decodeLossyStringIfPresent(forKey: .regulatedBy)
            yearsOfExperience = try container.decodeLossyStringIfPresent(forKey: .yearsOfExperience)
            linkedinUrl = try container.decodeLossyStringIfPresent(forKey: .linkedinUrl)
            twitterUrl = try container.decodeLossyStringIfPresent(forKey: .twitterUrl)
            facebookUrl = try container.decodeLossyStringIfPresent(forKey: .facebookUrl)
            websiteUrl = try container.decodeLossyStringIfPresent(forKey: .websiteUrl)
            bio = try container.decodeLossyStringIfPresent(forKey: .bio)
            examsPassed = try container.decodeLossyStringArray(forKey: .examsPassed)
            stateLicenses = try container.decodeLossyStringArray(forKey: .stateLicenses)
            previousFirms = try container.decodeLossyStringArray(forKey: .previousFirms)
            servicesOffered = try container.decodeLossyStringArray(forKey: .servicesOffered)
            clientTypes = try container.decodeLossyStringArray(forKey: .clientTypes)
            specialties = try container.decodeLossyStringArray(forKey: .specialties)
            reasonIfNotExists = try container.decodeLossyStringIfPresent(forKey: .reasonIfNotExists)
        }
    }

    struct Pipeline: Decodable {
        let finra: String?
        let web: String?
    }

    struct Model: Decodable {
        let primary: String?
        let used: String?
        let fallbackUsed: Bool?
    }

    struct Source: Decodable {
        let title: String?
        let uri: String?
    }

    let success: Bool?
    let profile: Profile?
    let pipeline: Pipeline?
    let model: Model?
    let sources: [Source]
    let warnings: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        profile = try container.decodeIfPresent(Profile.self, forKey: .profile)
        pipeline = try container.decodeIfPresent(Pipeline.self, forKey: .pipeline)
        model = try container.decodeIfPresent(Model.self, forKey: .model)
        sources = try container.decodeIfPresent([Source].self, forKey: .sources) ?? []
        warnings = try container.decodeLossyStringArray(forKey: .warnings)
    }

    private enum CodingKeys: String, CodingKey {
        case success
        case profile
        case pipeline
        case model
        case sources
        case warnings
    }

    func asDossier(submittedQuery: String) -> RIAProfileDossier {
        let resolvedProfile = profile
        let warnings = mergedWarnings(profile: resolvedProfile)
        let profileSources = legacyProfileSources(from: resolvedProfile)
        let sourceProfiles = sources.compactMap { source -> RIAProfileDossier.VerifiedProfile? in
            guard let url = source.uri?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else {
                return nil
            }

            let title = source.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            return .init(
                platform: title ?? "Public source",
                label: title,
                url: url,
                handle: nil,
                sourceTitle: title,
                sourceURL: url,
                evidenceNote: "Grounding source returned by the merged RIA profile API."
            )
        }

        return RIAProfileDossier(
            subject: .init(
                fullName: firstNonEmpty(resolvedProfile?.fullName, submittedQuery) ?? submittedQuery,
                crdNumber: resolvedProfile?.crdNumber,
                currentFirm: resolvedProfile?.currentFirm,
                location: resolvedProfile?.location
            ),
            executiveSummary: resolvedProfile?.bio ?? "",
            verifiedProfiles: Self.dedupeVerifiedProfiles(profileSources + sourceProfiles),
            publicImages: legacyPublicImages(from: resolvedProfile),
            keyFacts: legacyKeyFacts(from: resolvedProfile, sources: sources),
            unverifiedOrNotFound: warnings,
            promptsUsed: []
        )
    }

    private func mergedWarnings(profile: Profile?) -> [String] {
        var values = warnings

        if let reason = profile?.reasonIfNotExists?.trimmingCharacters(in: .whitespacesAndNewlines), !reason.isEmpty {
            values.append(reason)
        }

        if model?.fallbackUsed == true, let usedModel = model?.used, let primaryModel = model?.primary {
            values.append("Primary model \(primaryModel) failed; fallback model \(usedModel) was used.")
        }

        if let webStage = pipeline?.web, webStage.lowercased() != "completed" {
            values.append("Web enrichment finished with status: \(webStage).")
        }

        return Self.dedupedStrings(values)
    }

    private func legacyProfileSources(from profile: Profile?) -> [RIAProfileDossier.VerifiedProfile] {
        guard let profile else { return [] }

        let candidates: [(platform: String, label: String, url: String?, note: String)] = [
            ("LinkedIn", "Verified LinkedIn profile", profile.linkedinUrl, "Verified social profile returned by the merged RIA profile API."),
            ("X", "Verified X profile", profile.twitterUrl, "Verified social profile returned by the merged RIA profile API."),
            ("Facebook", "Verified Facebook profile", profile.facebookUrl, "Verified social profile returned by the merged RIA profile API."),
            ("Website", "Verified website", profile.websiteUrl, "Verified website returned by the merged RIA profile API.")
        ]

        return candidates.compactMap { candidate in
            guard let url = candidate.url?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else {
                return nil
            }

            return .init(
                platform: candidate.platform,
                label: candidate.label,
                url: url,
                handle: nil,
                sourceTitle: candidate.label,
                sourceURL: url,
                evidenceNote: candidate.note
            )
        }
    }

    private func legacyPublicImages(from profile: Profile?) -> [RIAProfileDossier.PublicImage] {
        guard
            let profile,
            let imageUrl = profile.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
            !imageUrl.isEmpty
        else {
            return []
        }

        let sourcePageURL = firstNonEmpty(profile.websiteUrl, profile.linkedinUrl, profile.facebookUrl, profile.twitterUrl)
        let kind = profile.isLikelyOrganization ? "company logo" : "headshot"

        return [
            .init(
                kind: kind,
                imageURL: imageUrl,
                sourcePageURL: sourcePageURL,
                sourceTitle: profile.currentFirm ?? profile.fullName,
                confidenceNote: "Validated image URL returned by the merged RIA profile API."
            )
        ]
    }

    private func legacyKeyFacts(
        from profile: Profile?,
        sources: [Source]
    ) -> [RIAProfileDossier.KeyFact] {
        guard let profile else { return [] }

        let sourceTitle = sources.first?.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceURL = sources.first?.uri?.trimmingCharacters(in: .whitespacesAndNewlines)

        let facts: [String?] = [
            profile.secNumber.map { "SEC number: \($0)" },
            profile.regulatedBy.map { "Regulated by \($0)." },
            profile.mainAddress.map { "Main address: \($0)" },
            profile.phone.map { "Public phone: \($0)" },
            profile.yearsOfExperience.map { "Approximate experience: \($0)" },
            joinedFact(label: "Other names", values: profile.otherNames),
            joinedFact(label: "Exams passed", values: profile.examsPassed),
            joinedFact(label: "State licenses", values: profile.stateLicenses),
            joinedFact(label: "Previous firms", values: profile.previousFirms),
            joinedFact(label: "Services offered", values: profile.servicesOffered),
            joinedFact(label: "Client types", values: profile.clientTypes),
            joinedFact(label: "Specialties", values: profile.specialties)
        ]

        return Self.dedupedStrings(facts.compactMap { $0 }).map { fact in
            .init(
                fact: fact,
                sourceTitle: sourceTitle,
                sourceURL: sourceURL,
                evidenceNote: "Merged profile fact returned by the legacy RIA profile API."
            )
        }
    }

    private static func dedupeVerifiedProfiles(
        _ profiles: [RIAProfileDossier.VerifiedProfile]
    ) -> [RIAProfileDossier.VerifiedProfile] {
        var seen: Set<String> = []
        var result: [RIAProfileDossier.VerifiedProfile] = []

        for profile in profiles {
            let key = [
                profile.url?.lowercased(),
                profile.sourceURL?.lowercased(),
                profile.label?.lowercased()
            ]
            .compactMap { $0 }
            .joined(separator: "|")

            if key.isEmpty || seen.contains(key) {
                continue
            }

            seen.insert(key)
            result.append(profile)
        }

        return result
    }

    private static func dedupedStrings(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []

        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let key = trimmed.lowercased()
            if seen.insert(key).inserted {
                result.append(trimmed)
            }
        }

        return result
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }

    private func joinedFact(label: String, values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        return "\(label): \(values.joined(separator: ", "))"
    }
}

private extension LegacyLookupResponse.Profile {
    var isLikelyOrganization: Bool {
        let value = [fullName, currentFirm]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: " ")

        guard !value.isEmpty else { return false }

        let organizationMarkers = [
            " llc",
            " inc",
            " ltd",
            " llp",
            " company",
            " advisors",
            " advisory",
            " securities",
            " capital",
            " wealth",
            " financial",
            " partners",
            " group",
            " markets",
            " bank"
        ]

        return organizationMarkers.contains(where: value.contains)
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyStringIfPresent(forKey key: Key) throws -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return String(doubleValue)
        }

        return nil
    }

    func decodeLossyStringArray(forKey key: Key) throws -> [String] {
        if let values = try? decodeIfPresent([String].self, forKey: key) {
            return values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        if let singleValue = try decodeLossyStringIfPresent(forKey: key) {
            return singleValue.isEmpty ? [] : [singleValue]
        }

        return []
    }
}
