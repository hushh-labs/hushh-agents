import Foundation

enum AuthProviderConfig {
    struct Google {
        let clientID: String
        let serverClientID: String
    }

    struct InternalAdmin {
        let email: String

        let expectedPasscode = "hushh1234"
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

    static var isInternalAdminModeEnabled: Bool {
        isInternalAdminBuild
            && configuredBool(forInfoKey: "DEV_ADMIN_ENABLED")
            && configuredValue(forInfoKey: "DEV_ADMIN_EMAIL") != nil
    }

    static var internalAdmin: InternalAdmin? {
        guard isInternalAdminModeEnabled,
              let email = configuredValue(forInfoKey: "DEV_ADMIN_EMAIL") else {
            return nil
        }
        return InternalAdmin(email: email)
    }

    private static var isInternalAdminBuild: Bool {
#if DEBUG
        true
#elseif targetEnvironment(simulator)
        true
#else
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    }

    private static func configuredValue(forInfoKey key: String) -> String? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !rawValue.contains("REPLACE_WITH"),
            !rawValue.hasPrefix("$(")            // unresolved build variable
        else {
            return nil
        }

        return rawValue
    }

    private static func configuredBool(forInfoKey key: String) -> Bool {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? Bool {
            return value
        }

        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return false
        }

        return NSString(string: rawValue).boolValue
    }
}
