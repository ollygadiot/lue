import SwiftUI

struct SetupView: View {
    @Bindable var viewModel: LightViewModel

    @State private var bridgeIP = ""
    @State private var isDiscovering = true
    @State private var isPairing = false
    @State private var pairError: String?
    @State private var apiKey: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.2")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Connect to Hue Bridge")
                .font(.headline)

            if isDiscovering {
                ProgressView("Searching for bridge...")
                    .font(.caption)
            } else {
                HStack(spacing: 8) {
                    TextField("Bridge IP", text: $bridgeIP)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await discover() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(isDiscovering)
                }
            }

            if let apiKey {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                    Text("Paired successfully!")
                        .font(.caption)

                    Button("Start") {
                        viewModel.configure(bridgeIP: bridgeIP, apiKey: apiKey)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if !isDiscovering {
                VStack(spacing: 8) {
                    Text("Press the link button on your Hue Bridge, then tap Pair below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button(isPairing ? "Pairing..." : "Pair") {
                        Task { await pair() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isPairing || bridgeIP.isEmpty)
                }

                if let pairError {
                    Text(pairError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(20)
        .frame(width: 280)
        .task {
            await discover()
        }
    }

    private func discover() async {
        isDiscovering = true
        pairError = nil

        do {
            let (data, _) = try await URLSession.shared.data(
                from: URL(string: "https://discovery.meethue.com")!
            )

            struct DiscoveryResult: Decodable {
                let id: String
                let internalipaddress: String
            }

            let results = try JSONDecoder().decode([DiscoveryResult].self, from: data)
            if let first = results.first {
                bridgeIP = first.internalipaddress
            }
        } catch {
            pairError = "Discovery failed — enter IP manually"
        }

        isDiscovering = false
    }

    private func pair() async {
        isPairing = true
        pairError = nil

        do {
            let session = URLSession(
                configuration: .default,
                delegate: TrustAllCertsDelegate(),
                delegateQueue: nil
            )

            var request = URLRequest(
                url: URL(string: "https://\(bridgeIP)/api")!
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            struct PairRequest: Encodable {
                let devicetype: String
                let generateclientkey: Bool
            }
            request.httpBody = try JSONEncoder().encode(
                PairRequest(devicetype: "LightWidget#macOS", generateclientkey: true)
            )

            let (data, _) = try await session.data(for: request)

            struct PairResponse: Decodable {
                let success: PairSuccess?
                let error: PairError?
            }
            struct PairSuccess: Decodable {
                let username: String
            }
            struct PairError: Decodable {
                let description: String
            }

            let responses = try JSONDecoder().decode([PairResponse].self, from: data)
            if let success = responses.first?.success {
                apiKey = success.username
            } else if let error = responses.first?.error {
                pairError = error.description
            }
        } catch {
            pairError = error.localizedDescription
        }

        isPairing = false
    }
}
