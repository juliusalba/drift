import Foundation
import Security

/// Secure credential storage using macOS Keychain.
enum KeychainService {
    private static let serviceName = "com.drift.bar"

    enum Key: String, CaseIterable {
        case unsplashAccessKey = "unsplash_access_key"
        case pexelsApiKey = "pexels_api_key"
        case figmaPersonalToken = "figma_personal_token"

        var displayName: String {
            switch self {
            case .unsplashAccessKey: return "Unsplash Access Key"
            case .pexelsApiKey: return "Pexels API Key"
            case .figmaPersonalToken: return "Figma Personal Access Token"
            }
        }

        var signupURL: URL? {
            switch self {
            case .unsplashAccessKey:
                return URL(string: "https://unsplash.com/developers")
            case .pexelsApiKey:
                return URL(string: "https://www.pexels.com/api/new/")
            case .figmaPersonalToken:
                return URL(string: "https://www.figma.com/developers/api#access-tokens")
            }
        }

        var helpText: String {
            switch self {
            case .unsplashAccessKey:
                return "Create a free app at unsplash.com/developers → copy the Access Key"
            case .pexelsApiKey:
                return "Sign up at pexels.com/api → copy your API key"
            case .figmaPersonalToken:
                return "Figma → Settings → Personal Access Tokens → Generate"
            }
        }
    }

    // MARK: - Save

    static func save(key: Key, value: String) -> Bool {
        let data = Data(value.utf8)

        // Delete existing first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Read

    static func read(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete

    @discardableResult
    static func delete(key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Check

    static func hasKey(_ key: Key) -> Bool {
        return read(key: key) != nil
    }

    // MARK: - Export for CLI scripts

    /// Writes credentials to a temporary env file that Python scripts can read.
    /// File is user-readable only (0600 permissions).
    static func exportForScripts() -> URL? {
        let tmpDir = FileManager.default.temporaryDirectory
        let envFile = tmpDir.appendingPathComponent("drift_credentials.env")

        var lines: [String] = []
        if let key = read(key: .unsplashAccessKey) {
            lines.append("UNSPLASH_ACCESS_KEY=\(key)")
        }
        if let key = read(key: .pexelsApiKey) {
            lines.append("PEXELS_API_KEY=\(key)")
        }
        if let key = read(key: .figmaPersonalToken) {
            lines.append("FIGMA_PERSONAL_TOKEN=\(key)")
        }

        guard !lines.isEmpty else { return nil }

        let content = lines.joined(separator: "\n")
        do {
            try content.write(to: envFile, atomically: true, encoding: .utf8)
            // Set permissions to owner-only read/write
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: envFile.path
            )
            return envFile
        } catch {
            return nil
        }
    }
}
