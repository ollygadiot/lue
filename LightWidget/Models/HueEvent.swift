import Foundation

// MARK: - SSE Event Models

struct HueSSEMessage: Decodable, Sendable {
    let creationtime: String
    let data: [HueEventData]
    let id: String
    let type: String
}

struct HueEventData: Decodable, Sendable {
    let id: String
    let type: String
    let on: OnState?
    let dimming: Dimming?
    let colorTemperature: ColorTemperature?
    let color: ColorInfo?
    let owner: ResourceReference?
    let status: SceneStatus?

    enum CodingKeys: String, CodingKey {
        case id, type, on, dimming, color, owner, status
        case colorTemperature = "color_temperature"
    }
}
