import Foundation

struct RIAProfileDossier: Codable {
    struct Subject: Codable {
        let fullName: String?
        let crdNumber: String?
        let currentFirm: String?
        let location: String?

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case crdNumber = "crd_number"
            case currentFirm = "current_firm"
            case location
        }

        init(
            fullName: String? = nil,
            crdNumber: String? = nil,
            currentFirm: String? = nil,
            location: String? = nil
        ) {
            self.fullName = fullName
            self.crdNumber = crdNumber
            self.currentFirm = currentFirm
            self.location = location
        }
    }

    struct VerifiedProfile: Codable, Identifiable {
        let platform: String?
        let label: String?
        let url: String?
        let handle: String?
        let sourceTitle: String?
        let sourceURL: String?
        let evidenceNote: String?

        enum CodingKeys: String, CodingKey {
            case platform
            case label
            case url
            case handle
            case sourceTitle = "source_title"
            case sourceURL = "source_url"
            case evidenceNote = "evidence_note"
        }

        var id: String {
            url ?? sourceURL ?? label ?? platform ?? UUID().uuidString
        }
    }

    struct PublicImage: Codable, Identifiable {
        let kind: String?
        let imageURL: String?
        let sourcePageURL: String?
        let sourceTitle: String?
        let confidenceNote: String?

        enum CodingKeys: String, CodingKey {
            case kind
            case imageURL = "image_url"
            case sourcePageURL = "source_page_url"
            case sourceTitle = "source_title"
            case confidenceNote = "confidence_note"
        }

        var id: String {
            imageURL ?? sourcePageURL ?? kind ?? UUID().uuidString
        }
    }

    struct KeyFact: Codable, Identifiable {
        let fact: String?
        let sourceTitle: String?
        let sourceURL: String?
        let evidenceNote: String?

        enum CodingKeys: String, CodingKey {
            case fact
            case sourceTitle = "source_title"
            case sourceURL = "source_url"
            case evidenceNote = "evidence_note"
        }

        var id: String {
            fact ?? sourceURL ?? sourceTitle ?? UUID().uuidString
        }
    }

    let subject: Subject
    let executiveSummary: String
    let verifiedProfiles: [VerifiedProfile]
    let publicImages: [PublicImage]
    let keyFacts: [KeyFact]
    let unverifiedOrNotFound: [String]
    let promptsUsed: [String]

    enum CodingKeys: String, CodingKey {
        case subject
        case executiveSummary = "executive_summary"
        case verifiedProfiles = "verified_profiles"
        case publicImages = "public_images"
        case keyFacts = "key_facts"
        case unverifiedOrNotFound = "unverified_or_not_found"
        case promptsUsed = "prompts_used"
    }

    init(
        subject: Subject = Subject(),
        executiveSummary: String = "",
        verifiedProfiles: [VerifiedProfile] = [],
        publicImages: [PublicImage] = [],
        keyFacts: [KeyFact] = [],
        unverifiedOrNotFound: [String] = [],
        promptsUsed: [String] = []
    ) {
        self.subject = subject
        self.executiveSummary = executiveSummary
        self.verifiedProfiles = verifiedProfiles
        self.publicImages = publicImages
        self.keyFacts = keyFacts
        self.unverifiedOrNotFound = unverifiedOrNotFound
        self.promptsUsed = promptsUsed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subject = try container.decodeIfPresent(Subject.self, forKey: .subject) ?? Subject()
        executiveSummary = try container.decodeIfPresent(String.self, forKey: .executiveSummary) ?? ""
        verifiedProfiles = try container.decodeIfPresent([VerifiedProfile].self, forKey: .verifiedProfiles) ?? []
        publicImages = try container.decodeIfPresent([PublicImage].self, forKey: .publicImages) ?? []
        keyFacts = try container.decodeIfPresent([KeyFact].self, forKey: .keyFacts) ?? []
        unverifiedOrNotFound = try container.decodeIfPresent([String].self, forKey: .unverifiedOrNotFound) ?? []
        promptsUsed = try container.decodeIfPresent([String].self, forKey: .promptsUsed) ?? []
    }

    var noConfidentMatch: Bool {
        subject.crdNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        subject.currentFirm?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        subject.location?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
        verifiedProfiles.isEmpty &&
        publicImages.isEmpty &&
        keyFacts.isEmpty
    }
}
