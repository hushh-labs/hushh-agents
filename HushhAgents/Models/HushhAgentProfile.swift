import Foundation

struct HushhAgentProfile: Codable, Identifiable {
    let id: UUID?
    let userId: UUID
    let catalogAgentId: String?
    let businessName: String
    let alias: String?
    let source: String
    let categories: [String]
    let services: [String]
    let specialties: String
    let history: String
    let representativeName: String
    let representativeRole: String
    let representativeBio: String
    let representativePhotoURL: String?
    let phone: String
    let formattedPhone: String
    let websiteURL: String
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
    let averageRating: Double
    let roundedRating: Double
    let reviewCount: Int
    let primaryPhotoURL: String?
    let photoCount: Int
    let photoList: [AgentPhoto]
    let isClosed: Bool
    let isChain: Bool
    let isYelpGuaranteed: Bool?
    let hours: [String]
    let yearEstablished: Int?
    let messagingEnabled: Bool
    let messagingType: String
    let messagingDisplayText: String
    let messagingResponseTime: String
    let messagingReplyRate: String
    let annotations: [AgentAnnotation]
    let businessURL: String
    let shareURL: String
    let profileStatus: String
    let discoveryEnabled: Bool
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case catalogAgentId = "catalog_agent_id"
        case businessName = "business_name"
        case alias
        case source
        case categories
        case services
        case specialties
        case history
        case representativeName = "representative_name"
        case representativeRole = "representative_role"
        case representativeBio = "representative_bio"
        case representativePhotoURL = "representative_photo_url"
        case phone
        case formattedPhone = "formatted_phone"
        case websiteURL = "website_url"
        case address1
        case address2
        case address3
        case city
        case state
        case zip
        case country
        case latitude
        case longitude
        case formattedAddress = "formatted_address"
        case shortAddress = "short_address"
        case averageRating = "average_rating"
        case roundedRating = "rounded_rating"
        case reviewCount = "review_count"
        case primaryPhotoURL = "primary_photo_url"
        case photoCount = "photo_count"
        case photoList = "photo_list"
        case isClosed = "is_closed"
        case isChain = "is_chain"
        case isYelpGuaranteed = "is_yelp_guaranteed"
        case hours
        case yearEstablished = "year_established"
        case messagingEnabled = "messaging_enabled"
        case messagingType = "messaging_type"
        case messagingDisplayText = "messaging_display_text"
        case messagingResponseTime = "messaging_response_time"
        case messagingReplyRate = "messaging_reply_rate"
        case annotations
        case businessURL = "business_url"
        case shareURL = "share_url"
        case profileStatus = "profile_status"
        case discoveryEnabled = "discovery_enabled"
        case updatedAt = "updated_at"
    }

    var isDiscoverable: Bool {
        profileStatus == "discoverable" && discoveryEnabled
    }

    var displayName: String {
        let trimmed = businessName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }

        let rep = representativeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return rep.isEmpty ? "RIA Profile" : rep
    }

    var representativeInitials: String {
        let source = representativeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "HA" }

        let parts = source.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }

        return String(source.prefix(2)).uppercased()
    }

    var displayPhotoURLString: String? {
        let rawValue = (primaryPhotoURL ?? representativePhotoURL ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawValue.isEmpty else { return nil }
        guard let updatedAt else { return rawValue }
        guard var components = URLComponents(string: rawValue) else { return rawValue }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "v" }
        queryItems.append(URLQueryItem(name: "v", value: updatedAt))
        components.queryItems = queryItems

        return components.url?.absoluteString ?? rawValue
    }

    var minimumRequiredFieldsComplete: Bool {
        let hasRep = !representativeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasContact = !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Query-first onboarding only guarantees a verified name plus a user-supplied phone number.
        // The rest of the profile can be enriched asynchronously from public records over time.
        return hasRep && hasContact
    }

    // MARK: - Convert to KirklandAgent (for deck display)

    func toKirklandAgent() -> KirklandAgent? {
        // Use user_id as the agent ID prefix to avoid collisions with seeded agents
        let agentId = "profile_\(userId.uuidString)"
        let resolvedPhotoURL = displayPhotoURLString ?? representativePhotoURL

        return KirklandAgent(
            id: agentId,
            name: businessName.isEmpty ? representativeName : businessName,
            alias: alias,
            source: source,
            location: AgentLocation(
                address1: address1,
                address2: address2,
                address3: address3,
                city: city,
                state: state,
                zip: zip,
                country: country,
                latitude: latitude,
                longitude: longitude,
                formattedAddress: formattedAddress,
                shortAddress: shortAddress
            ),
            contact: AgentContact(
                phone: phone,
                formattedPhone: formattedPhone,
                websiteUrl: websiteURL
            ),
            ratings: AgentRatings(
                averageRating: averageRating,
                roundedRating: roundedRating,
                reviewCount: reviewCount
            ),
            categories: categories,
            services: services,
            photos: AgentPhotos(
                primaryPhotoUrl: resolvedPhotoURL,
                photoCount: photoCount,
                photoList: resolvedPhotoURL.map {
                    [AgentPhoto(id: nil, url: $0, thumbnailUrl: nil, width: nil, height: nil, caption: nil)]
                } ?? photoList
            ),
            businessDetails: AgentBusinessDetails(
                isClosed: isClosed,
                isChain: isChain,
                isYelpGuaranteed: isYelpGuaranteed,
                hours: hours,
                yearEstablished: yearEstablished,
                specialties: specialties,
                history: history
            ),
            representative: AgentRepresentative(
                name: representativeName,
                bio: representativeBio,
                role: representativeRole,
                photoUrl: resolvedPhotoURL
            ),
            messaging: AgentMessaging(
                isEnabled: messagingEnabled,
                type: messagingType,
                displayText: messagingDisplayText,
                responseTime: messagingResponseTime,
                replyRate: messagingReplyRate
            ),
            annotations: annotations,
            yelpUrls: AgentYelpURLs(
                businessUrl: businessURL,
                shareUrl: shareURL
            )
        )
        .withTargetMetadata(
            kind: .profile,
            catalogAgentId: catalogAgentId,
            profileUserId: userId
        )
    }

    static func draft(for userId: UUID, fullName: String?, email: String?) -> HushhAgentProfile {
        HushhAgentProfile(
            id: nil,
            userId: userId,
            catalogAgentId: nil,
            businessName: "",
            alias: nil,
            source: "hushh_agents_app",
            categories: [],
            services: [],
            specialties: "",
            history: "",
            representativeName: fullName ?? "",
            representativeRole: "",
            representativeBio: "",
            representativePhotoURL: nil,
            phone: "",
            formattedPhone: "",
            websiteURL: "",
            address1: "",
            address2: "",
            address3: "",
            city: "",
            state: "",
            zip: "",
            country: "US",
            latitude: nil,
            longitude: nil,
            formattedAddress: "",
            shortAddress: "",
            averageRating: 0,
            roundedRating: 0,
            reviewCount: 0,
            primaryPhotoURL: nil,
            photoCount: 0,
            photoList: [],
            isClosed: false,
            isChain: false,
            isYelpGuaranteed: nil,
            hours: [],
            yearEstablished: nil,
            messagingEnabled: true,
            messagingType: "direct",
            messagingDisplayText: "Start the conversation",
            messagingResponseTime: "",
            messagingReplyRate: "",
            annotations: [],
            businessURL: "",
            shareURL: "",
            profileStatus: "draft",
            discoveryEnabled: true,
            updatedAt: nil
        )
    }
}
