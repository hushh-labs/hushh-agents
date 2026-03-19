import Foundation
import Supabase

final class UserService {

    func upsertUser(id: UUID, email: String?, fullName: String?, avatarUrl: String? = nil) async throws -> AppUser {
        // Check if user already exists — if so, only update safe fields
        // (email, name, avatar). NEVER overwrite onboarding_step for returning users.
        if let existing = try await fetchUser(id: id) {
            struct SafeUpdate: Encodable {
                let email: String?
                let name: String?
                let fullName: String?
                let avatarUrl: String?

                enum CodingKeys: String, CodingKey {
                    case email
                    case name
                    case fullName = "full_name"
                    case avatarUrl = "avatar_url"
                }
            }

            let update = SafeUpdate(
                email: email ?? existing.email,
                name: fullName ?? existing.fullName ?? existing.email,
                fullName: fullName ?? existing.fullName,
                avatarUrl: avatarUrl ?? existing.avatarUrl
            )

            let updated: AppUser = try await SupabaseService.shared.client
                .from("hushh_agents_users")
                .update(update)
                .eq("user_id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            return updated
        }

        // New user — insert with default onboarding state
        struct NewAccountRow: Encodable {
            let userId: UUID
            let email: String?
            let name: String?
            let fullName: String?
            let avatarUrl: String?
            let onboardingStep: String
            let profileVisibility: String
            let discoveryEnabled: Bool

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case email
                case name
                case fullName = "full_name"
                case avatarUrl = "avatar_url"
                case onboardingStep = "onboarding_step"
                case profileVisibility = "profile_visibility"
                case discoveryEnabled = "discovery_enabled"
            }
        }

        let row = NewAccountRow(
            userId: id,
            email: email,
            name: fullName ?? email,
            fullName: fullName,
            avatarUrl: avatarUrl,
            onboardingStep: "welcome",
            profileVisibility: "draft",
            discoveryEnabled: true
        )

        let user: AppUser = try await SupabaseService.shared.client
            .from("hushh_agents_users")
            .insert(row)
            .select()
            .single()
            .execute()
            .value

        return user
    }

    func fetchUser(id: UUID) async throws -> AppUser? {
        let users: [AppUser] = try await SupabaseService.shared.client
            .from("hushh_agents_users")
            .select()
            .eq("user_id", value: id.uuidString)
            .limit(1)
            .execute()
            .value

        return users.first
    }

    func updateUserAccount(
        userId: UUID,
        fullName: String?,
        phone: String?,
        step: String,
        profileVisibility: String,
        discoveryEnabled: Bool
    ) async throws {
        struct AccountUpdate: Encodable {
            let fullName: String?
            let phone: String?
            let onboardingStep: String
            let profileVisibility: String
            let discoveryEnabled: Bool
            let onboardingCompletedAt: String?

            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case phone
                case onboardingStep = "onboarding_step"
                case profileVisibility = "profile_visibility"
                case discoveryEnabled = "discovery_enabled"
                case onboardingCompletedAt = "onboarding_completed_at"
            }
        }

        try await SupabaseService.shared.client
            .from("hushh_agents_users")
            .update(
                AccountUpdate(
                    fullName: fullName,
                    phone: phone,
                    onboardingStep: step,
                    profileVisibility: profileVisibility,
                    discoveryEnabled: discoveryEnabled,
                    onboardingCompletedAt: step == "complete" ? ISO8601DateFormatter().string(from: Date()) : nil
                )
            )
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    func fetchAgentProfile(userId: UUID) async throws -> HushhAgentProfile? {
        let profiles: [HushhAgentProfile] = try await SupabaseService.shared.client
            .from("hushh_agents_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return profiles.first
    }

    func saveAgentProfile(_ profile: HushhAgentProfile) async throws -> HushhAgentProfile {
        let existingProfile = try await fetchAgentProfile(userId: profile.userId)
        let profileToSave = profile.withPersistedId(existingProfile?.id)

        if existingProfile != nil {
            let savedProfile: HushhAgentProfile = try await SupabaseService.shared.client
                .from("hushh_agents_profiles")
                .update(profileToSave)
                .eq("user_id", value: profile.userId.uuidString)
                .select()
                .single()
                .execute()
                .value

            return savedProfile
        }

        let savedProfile: HushhAgentProfile = try await SupabaseService.shared.client
            .from("hushh_agents_profiles")
            .insert(profileToSave)
            .select()
            .single()
            .execute()
            .value

        return savedProfile
    }

    /// Permanently deletes the user's Hushh Agents data via server-side RPC.
    /// Does NOT delete the shared auth.users row (other projects may use it).
    func deleteAccount() async throws {
        try await SupabaseService.shared.client
            .rpc("hushh_agents_delete_user_account")
            .execute()
    }

    func updateAgentProfileLocation(
        userId: UUID,
        location: ResolvedZipLocation
    ) async throws -> HushhAgentProfile {
        struct LocationUpdate: Encodable {
            let city: String
            let state: String
            let zip: String
            let formattedAddress: String
            let shortAddress: String

            enum CodingKeys: String, CodingKey {
                case city
                case state
                case zip
                case formattedAddress = "formatted_address"
                case shortAddress = "short_address"
            }
        }

        let savedProfile: HushhAgentProfile = try await SupabaseService.shared.client
            .from("hushh_agents_profiles")
            .update(
                LocationUpdate(
                    city: location.city,
                    state: location.state,
                    zip: location.zip,
                    formattedAddress: location.formattedAddress,
                    shortAddress: location.shortAddress
                )
            )
            .eq("user_id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value

        return savedProfile
    }
}

private extension HushhAgentProfile {
    func withPersistedId(_ id: UUID?) -> HushhAgentProfile {
        HushhAgentProfile(
            id: id ?? self.id,
            userId: userId,
            catalogAgentId: catalogAgentId,
            businessName: businessName,
            alias: alias,
            source: source,
            categories: categories,
            services: services,
            specialties: specialties,
            history: history,
            representativeName: representativeName,
            representativeRole: representativeRole,
            representativeBio: representativeBio,
            representativePhotoURL: representativePhotoURL,
            phone: phone,
            formattedPhone: formattedPhone,
            websiteURL: websiteURL,
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
            shortAddress: shortAddress,
            averageRating: averageRating,
            roundedRating: roundedRating,
            reviewCount: reviewCount,
            primaryPhotoURL: primaryPhotoURL,
            photoCount: photoCount,
            photoList: photoList,
            isClosed: isClosed,
            isChain: isChain,
            isYelpGuaranteed: isYelpGuaranteed,
            hours: hours,
            yearEstablished: yearEstablished,
            messagingEnabled: messagingEnabled,
            messagingType: messagingType,
            messagingDisplayText: messagingDisplayText,
            messagingResponseTime: messagingResponseTime,
            messagingReplyRate: messagingReplyRate,
            annotations: annotations,
            businessURL: businessURL,
            shareURL: shareURL,
            profileStatus: profileStatus,
            discoveryEnabled: discoveryEnabled,
            updatedAt: nil
        )
    }
}
