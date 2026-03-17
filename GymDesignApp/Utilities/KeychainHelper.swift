import Foundation
import Security

// MARK: - Keychain Helper

/// Lightweight wrapper around the iOS Keychain for secure storage of small data blobs.
struct KeychainHelper {

    // MARK: - Raw Data Operations

    /// Saves data to the Keychain for the given key. Updates the item if it already exists.
    @discardableResult
    static func save(_ data: Data, for key: String) -> Bool {
        // Attempt to delete any existing item first
        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            return updateStatus == errSecSuccess
        }

        return status == errSecSuccess
    }

    /// Reads data from the Keychain for the given key.
    static func read(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Deletes the Keychain item for the given key.
    @discardableResult
    static func delete(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - String Convenience

    /// Saves a string value to the Keychain.
    @discardableResult
    static func saveString(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(data, for: key)
    }

    /// Reads a string value from the Keychain.
    static func readString(for key: String) -> String? {
        guard let data = read(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Codable Convenience

    /// Encodes and saves a `Codable` value to the Keychain.
    @discardableResult
    static func save<T: Codable>(_ value: T, for key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return save(data, for: key)
    }

    /// Reads and decodes a `Codable` value from the Keychain.
    static func read<T: Codable>(for key: String) -> T? {
        guard let data = read(for: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
