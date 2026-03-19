import Foundation
import Supabase

final class ProfileImageUploadService {
    static let bucketId = "hushh-agent-profile-images"

    static func primaryPhotoPath(for userId: UUID) -> String {
        "\(userId.uuidString.lowercased())/primary.jpg"
    }

    func uploadPrimaryPhoto(data: Data, userId: UUID) async throws -> String {
        let path = Self.primaryPhotoPath(for: userId)

        _ = try await SupabaseService.shared.client.storage
            .from(Self.bucketId)
            .upload(
                path,
                data: data,
                options: FileOptions(
                    cacheControl: "60",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        return try SupabaseService.shared.client.storage
            .from(Self.bucketId)
            .getPublicURL(path: path)
            .absoluteString
    }
}
