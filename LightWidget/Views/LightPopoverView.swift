import SwiftUI

struct LightPopoverView: View {
    @Bindable var viewModel: LightViewModel

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading && viewModel.lights.isEmpty {
                ProgressView("Loading...")
                    .padding()
            } else if let error = viewModel.errorMessage, viewModel.lights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        viewModel.start()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                RoomHeaderView(viewModel: viewModel)

                if viewModel.roomOn {
                    Divider()
                    ScenePicker(viewModel: viewModel)
                }

                Divider()

                DisclosureGroup(
                    isExpanded: Binding(
                        get: { viewModel.isLightsExpanded },
                        set: { viewModel.isLightsExpanded = $0 }
                    )
                ) {
                    VStack(spacing: 6) {
                        ForEach(viewModel.sortedLights) { light in
                            LightRowView(light: light, viewModel: viewModel)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Individual lights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
