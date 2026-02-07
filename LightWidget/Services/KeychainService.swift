import Foundation

enum KeychainService {
    private static let prefix = "com.ollygadiot.LightWidget."

    static func save(key: String, value: String) throws {
        UserDefaults.standard.set(value, forKey: prefix + key)
    }

    static func load(key: String) -> String? {
        UserDefaults.standard.string(forKey: prefix + key)
    }

    static func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: prefix + key)
    }

    static func saveCodable<T: Encodable>(_ value: T, key: String) throws {
        let data = try JSONEncoder().encode(value)
        guard let string = String(data: data, encoding: .utf8) else { return }
        try save(key: key, value: string)
    }

    static func loadCodable<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let string = load(key: key),
              let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
