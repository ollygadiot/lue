import Foundation

actor HueBridgeService {
    private let bridgeIP: String
    private let apiKey: String
    private let session: URLSession

    private var baseURL: String { "https://\(bridgeIP)" }

    init(bridgeIP: String, apiKey: String) {
        self.bridgeIP = bridgeIP
        self.apiKey = apiKey
        self.session = URLSession(
            configuration: .default,
            delegate: TrustAllCertsDelegate(),
            delegateQueue: nil
        )
    }

    // MARK: - Fetch

    func fetchLights() async throws -> [HueLight] {
        let response: HueResponse<HueLight> = try await get(path: "/clip/v2/resource/light")
        return response.data
    }

    func fetchRooms() async throws -> [HueRoom] {
        let response: HueResponse<HueRoom> = try await get(path: "/clip/v2/resource/room")
        return response.data
    }

    func fetchScenes() async throws -> [HueScene] {
        let response: HueResponse<HueScene> = try await get(path: "/clip/v2/resource/scene")
        return response.data
    }

    func fetchGroupedLight(id: String) async throws -> HueGroupedLight {
        let response: HueResponse<HueGroupedLight> = try await get(
            path: "/clip/v2/resource/grouped_light/\(id)"
        )
        guard let groupedLight = response.data.first else {
            throw HueBridgeError.notFound("Grouped light \(id)")
        }
        return groupedLight
    }

    // MARK: - Control

    func setLightOn(id: String, on: Bool) async throws {
        try await put(path: "/clip/v2/resource/light/\(id)", body: OnStateRequest(on: on))
    }

    func setLightBrightness(id: String, brightness: Double) async throws {
        try await put(
            path: "/clip/v2/resource/light/\(id)",
            body: DimmingRequest(brightness: brightness)
        )
    }

    func setGroupedLightOn(id: String, on: Bool) async throws {
        try await put(
            path: "/clip/v2/resource/grouped_light/\(id)",
            body: OnStateRequest(on: on)
        )
    }

    func setGroupedLightBrightness(id: String, brightness: Double) async throws {
        try await put(
            path: "/clip/v2/resource/grouped_light/\(id)",
            body: DimmingRequest(brightness: brightness)
        )
    }

    func activateScene(id: String) async throws {
        try await put(path: "/clip/v2/resource/scene/\(id)", body: SceneRecallRequest())
    }

    // MARK: - SSE Event Stream

    func eventStream() -> AsyncThrowingStream<[HueEventData], Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: URL(string: "\(baseURL)/eventstream/clip/v2")!)
                    request.setValue(apiKey, forHTTPHeaderField: "hue-application-key")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw HueBridgeError.invalidResponse
                    }

                    var dataBuffer = ""
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            dataBuffer = String(line.dropFirst(6))
                        } else if line.isEmpty, !dataBuffer.isEmpty {
                            if let jsonData = dataBuffer.data(using: .utf8) {
                                let messages = try JSONDecoder().decode(
                                    [HueSSEMessage].self, from: jsonData
                                )
                                let events = messages.flatMap(\.data)
                                if !events.isEmpty {
                                    continuation.yield(events)
                                }
                            }
                            dataBuffer = ""
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private HTTP Helpers

    private func get<T: Decodable>(path: String) async throws -> T {
        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.setValue(apiKey, forHTTPHeaderField: "hue-application-key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HueBridgeError.invalidResponse
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func put<T: Encodable>(path: String, body: T) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.httpMethod = "PUT"
        request.setValue(apiKey, forHTTPHeaderField: "hue-application-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HueBridgeError.invalidResponse
        }
    }
}

// MARK: - Errors

enum HueBridgeError: LocalizedError {
    case invalidResponse
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid response from Hue Bridge"
        case .notFound(let resource):
            "\(resource) not found"
        }
    }
}
