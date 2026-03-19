import CoreLocation
import Foundation

struct ResolvedZipLocation {
    let city: String
    let state: String
    let zip: String
    let formattedAddress: String
    let shortAddress: String
}

final class ZipLocationResolver {
    private let geocoder = CLGeocoder()

    func resolve(zip: String) async -> ResolvedZipLocation {
        let normalizedZip = zip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedZip.isEmpty else {
            return ResolvedZipLocation(
                city: "",
                state: "",
                zip: "",
                formattedAddress: "",
                shortAddress: ""
            )
        }

        do {
            let placemarks = try await geocode(zip: normalizedZip)
            if let placemark = placemarks.first {
                let city = placemark.locality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let state = placemark.administrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let shortAddress = [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
                let formattedAddress = [city, state, normalizedZip].filter { !$0.isEmpty }.joined(separator: ", ")

                return ResolvedZipLocation(
                    city: city,
                    state: state,
                    zip: normalizedZip,
                    formattedAddress: formattedAddress.isEmpty ? normalizedZip : formattedAddress,
                    shortAddress: shortAddress.isEmpty ? normalizedZip : shortAddress
                )
            }
        } catch {
            print("[ZipLocationResolver] Failed to resolve ZIP \(normalizedZip): \(error.localizedDescription)")
        }

        return ResolvedZipLocation(
            city: "",
            state: "",
            zip: normalizedZip,
            formattedAddress: normalizedZip,
            shortAddress: normalizedZip
        )
    }

    private func geocode(zip: String) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString("\(zip), USA") { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemarks ?? [])
                }
            }
        }
    }
}
