//
//  LeadService.swift
//  HushhAgents
//
//  Handles claim resolution and lead request management via Supabase.
//

import Foundation
import Supabase

enum ClaimAvailability {
    case unavailable
    case claimable(agentProfileId: UUID)
}

final class LeadService {

    static let shared = LeadService()

    private init() {}

    // MARK: - Claim Resolution

    /// Checks whether a Kirkland agent can be claimed by looking up matching agent_profiles.
    func resolveClaimTarget(kirklandAgentId: String) async -> ClaimAvailability {
        do {
            // Look up the kirkland agent name first
            let agents: [KirklandAgent] = try await SupabaseService.shared.client
                .from("kirkland_agents")
                .select()
                .eq("id", value: kirklandAgentId)
                .limit(1)
                .execute()
                .value

            guard let agent = agents.first else {
                return .unavailable
            }

            // Check if there's a matching agent profile by name
            struct AgentProfile: Decodable {
                let id: UUID
                let businessName: String?

                enum CodingKeys: String, CodingKey {
                    case id
                    case businessName = "business_name"
                }
            }

            let profiles: [AgentProfile] = try await SupabaseService.shared.client
                .from("agent_profiles")
                .select("id, business_name")
                .ilike("business_name", pattern: "%\(agent.name)%")
                .limit(1)
                .execute()
                .value

            if let profile = profiles.first {
                return .claimable(agentProfileId: profile.id)
            } else {
                return .unavailable
            }
        } catch {
            print("[LeadService] resolveClaimTarget failed: \(error.localizedDescription)")
            return .unavailable
        }
    }

    // MARK: - Lead Requests

    /// Creates a new lead / claim request.
    /// The `id` field is omitted so that Supabase auto-generates it.
    func createLeadRequest(
        userId: UUID,
        agentId: UUID,
        message: String,
        preferredChannel: String = "in_app",
        urgency: String = "normal",
        status: String = "pending"
    ) async throws {

        struct LeadRequestInsert: Encodable {
            let userId: UUID
            let agentId: UUID
            let message: String
            let preferredChannel: String
            let urgency: String
            let status: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case agentId = "agent_id"
                case message
                case preferredChannel = "preferred_channel"
                case urgency
                case status
            }
        }

        let row = LeadRequestInsert(
            userId: userId,
            agentId: agentId,
            message: message,
            preferredChannel: preferredChannel,
            urgency: urgency,
            status: status
        )

        try await SupabaseService.shared.client
            .from("lead_requests")
            .insert(row)
            .execute()
    }

    /// Fetches all lead / claim requests submitted by the given user.
    func fetchMyClaims(userId: UUID) async throws -> [LeadRequest] {
        let claims: [LeadRequest] = try await SupabaseService.shared.client
            .from("lead_requests")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return claims
    }
}
