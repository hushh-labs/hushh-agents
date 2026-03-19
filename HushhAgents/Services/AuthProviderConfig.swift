import Foundation

enum AuthProviderConfig {
    struct Google {
        let clientID: String
        let serverClientID: String
    }

    static var google: Google? {
        guard
            let clientID = configuredValue(forInfoKey: "GIDClientID"),
            let serverClientID = configuredValue(forInfoKey: "GIDServerClientID")
        else {
            return nil
        }

        return Google(clientID: clientID, serverClientID: serverClientID)
    }

    private static func configuredValue(forInfoKey key: String) -> String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !rawValue.contains("REPLACE_WITH")
        else {
            return nil
        }

        return rawValue
    }
}
