import Foundation

// MARK: - Root Wrapper

enum AgentTargetKind: String, Codable {
    case catalog
    case profile
}

struct AgentSeedData: Codable {
    let metadata: AgentMetadata?
    let agents: [KirklandAgent]

    enum CodingKeys: String, CodingKey {
        case metadata
        case agents
    }
}

struct AgentMetadata: Codable {
    let generatedAt: String?
    let source: String?
    let searchQuery: String?
    let searchLocation: String?
    let agentsCaptured: Int?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case source
        case searchQuery = "search_query"
        case searchLocation = "search_location"
        case agentsCaptured = "agents_captured"
    }
}

// MARK: - Main Agent Model

struct DeckImageCandidate: Identifiable {
    enum Source {
        case photoList
        case representative
        case primary
    }

    let url: URL
    let width: Int?
    let height: Int?
    let source: Source

    var id: String { url.absoluteString }

    var minimumDimension: Int? {
        guard let width, let height else { return nil }
        return min(width, height)
    }

    private var pixelArea: Int {
        guard let width, let height else { return 0 }
        return width * height
    }

    private var aspectRatio: Double? {
        guard let width, let height, height > 0 else { return nil }
        return Double(width) / Double(height)
    }

    private var isEditorialAspectPreferred: Bool {
        guard let aspectRatio else { return false }
        return (0.65...1.1).contains(aspectRatio)
    }

    static func sortForDeck(_ lhs: DeckImageCandidate, _ rhs: DeckImageCandidate) -> Bool {
        if lhs.isEditorialAspectPreferred != rhs.isEditorialAspectPreferred {
            return lhs.isEditorialAspectPreferred && !rhs.isEditorialAspectPreferred
        }

        if lhs.pixelArea != rhs.pixelArea {
            return lhs.pixelArea > rhs.pixelArea
        }

        return lhs.id < rhs.id
    }
}

struct KirklandAgent: Codable, Identifiable {
    let id: String
    let name: String
    let alias: String?
    let source: String?

    let location: AgentLocation
    let contact: AgentContact
    let ratings: AgentRatings
    let categories: [String]
    let services: [String]
    let photos: AgentPhotos
    let businessDetails: AgentBusinessDetails
    let representative: AgentRepresentative
    let messaging: AgentMessaging
    let annotations: [AgentAnnotation]
    let yelpUrls: AgentYelpURLs
    var targetKind: AgentTargetKind = .catalog
    var targetCatalogAgentId: String? = nil
    var targetProfileUserId: UUID? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, alias, source
        case location, contact, ratings, categories, services, photos
        case businessDetails = "business_details"
        case representative, messaging, annotations
        case yelpUrls = "yelp_urls"
    }

    // MARK: - Convenience Computed Properties (backward compatible)

    var phone: String? {
        let p = contact.phone
        return p.isEmpty ? nil : p
    }

    var localizedPhone: String? {
        let p = contact.formattedPhone
        return p.isEmpty ? nil : p
    }

    var city: String? {
        let c = location.city
        return c.isEmpty ? nil : c
    }

    var state: String? {
        let s = location.state
        return s.isEmpty ? nil : s
    }

    var zip: String? {
        let z = location.zip
        return z.isEmpty ? nil : z
    }

    var address1: String? {
        let a = location.address1
        return a.isEmpty ? nil : a
    }

    var latitude: Double? { location.latitude }
    var longitude: Double? { location.longitude }

    var avgRating: Double? { ratings.averageRating }
    var reviewCount: Int { ratings.reviewCount }

    var formattedAddress: String {
        if !location.formattedAddress.isEmpty {
            return location.formattedAddress
        }
        let parts = [location.address1, location.city, location.state, location.zip].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    var formattedRating: String {
        String(format: "%.1f (%d reviews)", ratings.averageRating, ratings.reviewCount)
    }

    var primaryPhotoURL: URL? {
        // Prefer primary_photo_url from the photos object
        if let urlString = photos.primaryPhotoUrl, let url = URL(string: urlString) {
            return url
        }
        // Fallback to first photo in list
        if let first = photos.photoList.first, let url = URL(string: first.url) {
            return url
        }
        return nil
    }

    var deckImageCandidates: [DeckImageCandidate] {
        var orderedCandidates = photos.photoList
            .compactMap { photo -> DeckImageCandidate? in
                guard
                    let width = photo.width,
                    let height = photo.height,
                    min(width, height) >= 320,
                    let url = URL(string: photo.url)
                else {
                    return nil
                }

                return DeckImageCandidate(
                    url: url,
                    width: width,
                    height: height,
                    source: .photoList
                )
            }
            .sorted(by: DeckImageCandidate.sortForDeck)

        if let urlString = representative.photoUrl, let url = URL(string: urlString) {
            orderedCandidates.append(
                DeckImageCandidate(
                    url: url,
                    width: nil,
                    height: nil,
                    source: .representative
                )
            )
        }

        if let urlString = photos.primaryPhotoUrl, let url = URL(string: urlString) {
            orderedCandidates.append(
                DeckImageCandidate(
                    url: url,
                    width: nil,
                    height: nil,
                    source: .primary
                )
            )
        }

        var seen = Set<String>()
        return orderedCandidates.filter { candidate in
            seen.insert(candidate.id).inserted
        }
    }

    var websiteURL: URL? {
        let urlString = contact.websiteUrl
        guard !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }

    var bio: String? {
        // Use representative bio or business history or specialties
        if !representative.bio.isEmpty { return representative.bio }
        if !businessDetails.history.isEmpty { return businessDetails.history }
        if !businessDetails.specialties.isEmpty { return businessDetails.specialties }
        return nil
    }

    var website: String? {
        let w = contact.websiteUrl
        return w.isEmpty ? nil : w
    }

    var resolvedCatalogAgentId: String? {
        if targetKind == .catalog {
            return targetCatalogAgentId ?? id
        }
        return targetCatalogAgentId
    }

    var deckTargetKey: String {
        switch targetKind {
        case .catalog:
            return "catalog:\(resolvedCatalogAgentId ?? id)"
        case .profile:
            return "profile:\(targetProfileUserId?.uuidString.lowercased() ?? id)"
        }
    }

    var canonicalDeckIdentityKey: String {
        if let catalogAgentId = resolvedCatalogAgentId {
            return "catalog:\(catalogAgentId)"
        }
        if let targetProfileUserId {
            return "profile:\(targetProfileUserId.uuidString.lowercased())"
        }
        return deckTargetKey
    }

    func withTargetMetadata(
        kind: AgentTargetKind,
        catalogAgentId: String?,
        profileUserId: UUID?
    ) -> KirklandAgent {
        var copy = self
        copy.targetKind = kind
        copy.targetCatalogAgentId = catalogAgentId
        copy.targetProfileUserId = profileUserId
        return copy
    }
}

// MARK: - Sub-Models

struct AgentLocation: Codable {
    let address1: String
    let address2: String
    let address3: String
    let city: String
    let state: String
    let zip: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    let formattedAddress: String
    let shortAddress: String

    enum CodingKeys: String, CodingKey {
        case address1, address2, address3, city, state, zip, country
        case latitude, longitude
        case formattedAddress = "formatted_address"
        case shortAddress = "short_address"
    }
}

struct AgentContact: Codable {
    let phone: String
    let formattedPhone: String
    let websiteUrl: String

    enum CodingKeys: String, CodingKey {
        case phone
        case formattedPhone = "formatted_phone"
        case websiteUrl = "website_url"
    }
}

struct AgentRatings: Codable {
    let averageRating: Double
    let roundedRating: Double
    let reviewCount: Int

    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case roundedRating = "rounded_rating"
        case reviewCount = "review_count"
    }
}

struct AgentPhotos: Codable {
    let primaryPhotoUrl: String?
    let photoCount: Int
    let photoList: [AgentPhoto]

    enum CodingKeys: String, CodingKey {
        case primaryPhotoUrl = "primary_photo_url"
        case photoCount = "photo_count"
        case photoList = "photo_list"
    }
}

struct AgentPhoto: Codable, Identifiable {
    let id: String?
    let url: String
    let thumbnailUrl: String?
    let width: Int?
    let height: Int?
    let caption: String?

    enum CodingKeys: String, CodingKey {
        case id, url
        case thumbnailUrl = "thumbnail_url"
        case width, height, caption
    }
}

struct AgentBusinessDetails: Codable {
    let isClosed: Bool
    let isChain: Bool
    let isYelpGuaranteed: Bool?
    let hours: [String]
    let yearEstablished: Int?
    let specialties: String
    let history: String

    enum CodingKeys: String, CodingKey {
        case isClosed = "is_closed"
        case isChain = "is_chain"
        case isYelpGuaranteed = "is_yelp_guaranteed"
        case hours
        case yearEstablished = "year_established"
        case specialties, history
    }
}

struct AgentRepresentative: Codable {
    let name: String
    let bio: String
    let role: String
    let photoUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, bio, role
        case photoUrl = "photo_url"
    }
}

struct AgentMessaging: Codable {
    let isEnabled: Bool
    let type: String
    let displayText: String
    let responseTime: String
    let replyRate: String

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case type
        case displayText = "display_text"
        case responseTime = "response_time"
        case replyRate = "reply_rate"
    }
}

struct AgentAnnotation: Codable, Identifiable {
    let type: String?
    let title: String

    var id: String { type ?? title }
}

struct AgentYelpURLs: Codable {
    let businessUrl: String
    let shareUrl: String

    enum CodingKeys: String, CodingKey {
        case businessUrl = "business_url"
        case shareUrl = "share_url"
    }
}
