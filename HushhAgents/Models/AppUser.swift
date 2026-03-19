import Foundation

struct AppUser: Codable {
    let rowId: UUID?
    let id: UUID
    let email: String?
    let phone: String?
    let fullName: String?
    let avatarUrl: String?
    let onboardingStep: String?
    let profileVisibility: String?
    let discoveryEnabled: Bool?
    let metadata: [String: AnyCodableValue]?

    enum CodingKeys: String, CodingKey {
        case rowId = "id"
        case id = "user_id"
        case email
        case phone
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case onboardingStep = "onboarding_step"
        case profileVisibility = "profile_visibility"
        case discoveryEnabled = "discovery_enabled"
        case metadata
    }

    // MARK: - Computed Properties

    var isOnboardingComplete: Bool {
        onboardingStep == "complete"
    }

    var isDiscoverable: Bool {
        profileVisibility == "discoverable" && (discoveryEnabled ?? false)
    }

    var displayName: String {
        if let name = fullName, !name.isEmpty {
            return name
        }
        if let email = email, !email.isEmpty {
            return email
        }
        return "User"
    }

    func updating(
        email: String? = nil,
        phone: String? = nil,
        fullName: String? = nil,
        avatarUrl: String? = nil,
        onboardingStep: String? = nil,
        profileVisibility: String? = nil,
        discoveryEnabled: Bool? = nil,
        metadata: [String: AnyCodableValue]? = nil
    ) -> AppUser {
        AppUser(
            rowId: rowId,
            id: id,
            email: email ?? self.email,
            phone: phone ?? self.phone,
            fullName: fullName ?? self.fullName,
            avatarUrl: avatarUrl ?? self.avatarUrl,
            onboardingStep: onboardingStep ?? self.onboardingStep,
            profileVisibility: profileVisibility ?? self.profileVisibility,
            discoveryEnabled: discoveryEnabled ?? self.discoveryEnabled,
            metadata: metadata ?? self.metadata
        )
    }
}

// MARK: - AnyCodableValue

/// A type-erased Codable value for flexible JSON metadata.
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else if let arrayVal = try? container.decode([AnyCodableValue].self) {
            self = .array(arrayVal)
        } else if let dictVal = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dictVal)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let val): try container.encode(val)
        case .int(let val): try container.encode(val)
        case .double(let val): try container.encode(val)
        case .bool(let val): try container.encode(val)
        case .array(let val): try container.encode(val)
        case .dictionary(let val): try container.encode(val)
        case .null: try container.encodeNil()
        }
    }
}
