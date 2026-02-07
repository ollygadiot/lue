import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class LightViewModel {
    // MARK: - State

    var isConfigured = false
    var isLoading = false
    var errorMessage: String?

    var roomOn = false
    var roomBrightness: Double = 0

    var lights: [HueLight] = []
    var scenes: [HueScene] = []
    var activeSceneId: String?

    var isLightsExpanded = false

    // MARK: - Configuration

    private static let bridgeIPKey = "bridgeIP"
    private static let apiKeyKey = "apiKey"
    private static let werkkamerRoomId = "e6c47b56-b721-40f2-a545-8e5b3effb047"
    private static let werkkamerGroupedLightId = "183481fa-4e2a-4d0f-81c5-5f893eab968b"

    private var service: HueBridgeService?
    private var sseTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func start() {
        guard let bridgeIP = KeychainService.load(key: Self.bridgeIPKey),
              let apiKey = KeychainService.load(key: Self.apiKeyKey) else {
            isConfigured = false
            return
        }

        isConfigured = true
        service = HueBridgeService(bridgeIP: bridgeIP, apiKey: apiKey)
        Task { await loadInitialState() }
        startSSE()
    }

    func configure(bridgeIP: String, apiKey: String) {
        try? KeychainService.save(key: Self.bridgeIPKey, value: bridgeIP)
        try? KeychainService.save(key: Self.apiKeyKey, value: apiKey)
        start()
    }

    func stop() {
        sseTask?.cancel()
    }

    // MARK: - Data Loading

    private func loadInitialState() async {
        guard let service else { return }
        isLoading = true
        errorMessage = nil

        do {
            let allLights = try await service.fetchLights()
            let allScenes = try await service.fetchScenes()
            let grouped = try await service.fetchGroupedLight(id: Self.werkkamerGroupedLightId)

            let roomLightIds = try await werkkamerLightIds(service: service)
            lights = allLights.filter { roomLightIds.contains($0.id) }
            scenes = allScenes.filter { $0.group.rid == Self.werkkamerRoomId }

            roomOn = grouped.on.on
            roomBrightness = grouped.dimming?.brightness ?? 0

            activeSceneId = scenes.first { $0.status?.active == "active" }?.id
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func werkkamerLightIds(service: HueBridgeService) async throws -> Set<String> {
        let rooms = try await service.fetchRooms()
        guard let werkkamer = rooms.first(where: { $0.id == Self.werkkamerRoomId }) else {
            return []
        }

        let deviceIds = Set(werkkamer.children.map(\.rid))
        let allLights = try await service.fetchLights()
        return Set(allLights.filter { deviceIds.contains($0.owner.rid) }.map(\.id))
    }

    // MARK: - Room Controls

    func toggleRoom() {
        let newState = !roomOn
        roomOn = newState
        let service = self.service
        let groupId = Self.werkkamerGroupedLightId
        Task.detached {
            try? await service?.setGroupedLightOn(id: groupId, on: newState)
        }
    }

    func setRoomBrightness(_ brightness: Double) {
        roomBrightness = brightness
        let service = self.service
        let groupId = Self.werkkamerGroupedLightId
        Task.detached {
            try? await service?.setGroupedLightBrightness(id: groupId, brightness: brightness)
        }
    }

    // MARK: - Light Controls

    func toggleLight(_ light: HueLight) {
        let newState = !light.on.on
        updateLightState(id: light.id, on: newState)
        let service = self.service
        let lightId = light.id
        Task.detached {
            try? await service?.setLightOn(id: lightId, on: newState)
        }
    }

    func setLightBrightness(_ light: HueLight, brightness: Double) {
        updateLightBrightness(id: light.id, brightness: brightness)
        let service = self.service
        let lightId = light.id
        Task.detached {
            try? await service?.setLightBrightness(id: lightId, brightness: brightness)
        }
    }

    // MARK: - Scene Controls

    func activateScene(_ scene: HueScene) {
        activeSceneId = scene.id
        let service = self.service
        let sceneId = scene.id
        Task {
            try? await service?.activateScene(id: sceneId)
            try? await Task.sleep(for: .milliseconds(500))
            await loadInitialState()
        }
    }

    // MARK: - SSE

    private func startSSE() {
        sseTask?.cancel()
        let service = self.service
        sseTask = Task { [weak self] in
            guard let service else { return }
            while !Task.isCancelled {
                do {
                    for try await events in await service.eventStream() {
                        self?.handleSSEEvents(events)
                    }
                } catch {
                    try? await Task.sleep(for: .seconds(5))
                }
            }
        }
    }

    private func handleSSEEvents(_ events: [HueEventData]) {
        for event in events {
            switch event.type {
            case "light":
                if let on = event.on {
                    updateLightState(id: event.id, on: on.on)
                }
                if let dimming = event.dimming {
                    updateLightBrightness(id: event.id, brightness: dimming.brightness)
                }
            case "grouped_light" where event.id == Self.werkkamerGroupedLightId:
                if let on = event.on {
                    roomOn = on.on
                }
                if let dimming = event.dimming {
                    roomBrightness = dimming.brightness
                }
            case "scene":
                if event.status?.active == "active" {
                    activeSceneId = event.id
                }
            default:
                break
            }
        }
    }

    // MARK: - State Helpers

    private func updateLightState(id: String, on: Bool) {
        guard let index = lights.firstIndex(where: { $0.id == id }) else { return }
        let light = lights[index]
        lights[index] = HueLight(
            id: light.id,
            metadata: light.metadata,
            on: OnState(on: on),
            dimming: light.dimming,
            colorTemperature: light.colorTemperature,
            color: light.color,
            owner: light.owner
        )
    }

    private func updateLightBrightness(id: String, brightness: Double) {
        guard let index = lights.firstIndex(where: { $0.id == id }) else { return }
        let light = lights[index]
        lights[index] = HueLight(
            id: light.id,
            metadata: light.metadata,
            on: light.on,
            dimming: Dimming(brightness: brightness, minDimLevel: light.dimming?.minDimLevel),
            colorTemperature: light.colorTemperature,
            color: light.color,
            owner: light.owner
        )
    }

    // MARK: - Computed

    var anyLightOn: Bool {
        lights.contains { $0.on.on } || roomOn
    }

    var sortedLights: [HueLight] {
        lights.sorted { $0.metadata.name < $1.metadata.name }
    }

    var sortedScenes: [HueScene] {
        let order = ["Bright", "Concentrate", "Read", "Relax", "Energize", "Nightlight"]
        return scenes.sorted { a, b in
            let ai = order.firstIndex(of: a.metadata.name) ?? order.count
            let bi = order.firstIndex(of: b.metadata.name) ?? order.count
            return ai < bi
        }
    }
}
