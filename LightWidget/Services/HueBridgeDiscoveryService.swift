import Foundation

enum HueBridgeDiscoveryService {
    private static let discoveryURL = URL(string: "https://discovery.meethue.com")!

    static func discoverBridgeIPs() async throws -> [String] {
        let (data, _) = try await URLSession.shared.data(from: discoveryURL)
        let results = try JSONDecoder().decode([DiscoveryResult].self, from: data)
        return results.map(\.internalipaddress)
    }

    static func discoverBridgeIP(apiKey: String? = nil) async throws -> String? {
        let bridgeIPs = try await discoverBridgeIPs()

        guard let apiKey else {
            return bridgeIPs.first
        }

        for bridgeIP in bridgeIPs {
            if await validatesBridgeIP(bridgeIP, apiKey: apiKey) {
                return bridgeIP
            }
        }

        return nil
    }

    private static func validatesBridgeIP(_ bridgeIP: String, apiKey: String) async -> Bool {
        do {
            let service = HueBridgeService(bridgeIP: bridgeIP, apiKey: apiKey)
            _ = try await service.fetchRooms()
            return true
        } catch {
            return false
        }
    }
}

private struct DiscoveryResult: Decodable {
    let internalipaddress: String
}
