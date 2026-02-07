import Foundation

// MARK: - API Response Wrapper

struct HueResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let errors: [HueError]
    let data: [T]
}

struct HueError: Decodable, Sendable {
    let description: String
}

// MARK: - Light

struct HueLight: Decodable, Identifiable, Sendable {
    let id: String
    let metadata: LightMetadata
    let on: OnState
    let dimming: Dimming?
    let colorTemperature: ColorTemperature?
    let color: ColorInfo?
    let owner: ResourceReference

    enum CodingKeys: String, CodingKey {
        case id, metadata, on, dimming, color, owner
        case colorTemperature = "color_temperature"
    }

    init(
        id: String,
        metadata: LightMetadata,
        on: OnState,
        dimming: Dimming?,
        colorTemperature: ColorTemperature?,
        color: ColorInfo?,
        owner: ResourceReference
    ) {
        self.id = id
        self.metadata = metadata
        self.on = on
        self.dimming = dimming
        self.colorTemperature = colorTemperature
        self.color = color
        self.owner = owner
    }
}

struct LightMetadata: Decodable, Sendable {
    let name: String
    let archetype: String?
}

struct OnState: Decodable, Sendable {
    let on: Bool
}

struct Dimming: Decodable, Sendable {
    let brightness: Double
    let minDimLevel: Double?

    enum CodingKeys: String, CodingKey {
        case brightness
        case minDimLevel = "min_dim_level"
    }
}

struct ColorTemperature: Decodable, Sendable {
    let mirek: Int?
    let mirekValid: Bool?
    let mirekSchema: MirekSchema?

    enum CodingKeys: String, CodingKey {
        case mirek
        case mirekValid = "mirek_valid"
        case mirekSchema = "mirek_schema"
    }
}

struct MirekSchema: Decodable, Sendable {
    let mirekMinimum: Int
    let mirekMaximum: Int

    enum CodingKeys: String, CodingKey {
        case mirekMinimum = "mirek_minimum"
        case mirekMaximum = "mirek_maximum"
    }
}

struct ColorInfo: Decodable, Sendable {
    let xy: XYColor?
}

struct XYColor: Decodable, Sendable {
    let x: Double
    let y: Double
}

struct ResourceReference: Decodable, Sendable {
    let rid: String
    let rtype: String
}

// MARK: - Room

struct HueRoom: Decodable, Identifiable, Sendable {
    let id: String
    let metadata: RoomMetadata
    let children: [ResourceReference]
    let services: [ResourceReference]
}

struct RoomMetadata: Decodable, Sendable {
    let name: String
    let archetype: String?
}

// MARK: - Grouped Light

struct HueGroupedLight: Decodable, Identifiable, Sendable {
    let id: String
    let on: OnState
    let dimming: Dimming?
}

// MARK: - Scene

struct HueScene: Decodable, Identifiable, Sendable {
    let id: String
    let metadata: SceneMetadata
    let group: ResourceReference
    let status: SceneStatus?
}

struct SceneMetadata: Decodable, Sendable {
    let name: String
    let image: ResourceReference?
}

struct SceneStatus: Decodable, Sendable {
    let active: String?
}

// MARK: - API Request Bodies

struct OnStateRequest: Encodable, Sendable {
    let on: OnValue

    struct OnValue: Encodable, Sendable {
        let on: Bool
    }

    init(on: Bool) {
        self.on = OnValue(on: on)
    }
}

struct DimmingRequest: Encodable, Sendable {
    let dimming: BrightnessValue

    struct BrightnessValue: Encodable, Sendable {
        let brightness: Double
    }

    init(brightness: Double) {
        self.dimming = BrightnessValue(brightness: brightness)
    }
}

struct SceneRecallRequest: Encodable, Sendable {
    let recall: RecallAction

    struct RecallAction: Encodable, Sendable {
        let action: String
    }

    init() {
        self.recall = RecallAction(action: "active")
    }
}
