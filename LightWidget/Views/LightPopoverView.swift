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

                Divider()

                CollapsibleSection(
                    title: "Individual lights",
                    isExpanded: $viewModel.isLightsExpanded
                ) {
                    VStack(spacing: 6) {
                        ForEach(viewModel.sortedLights) { light in
                            LightRowView(light: light, viewModel: viewModel)
                        }
                    }
                }

                if viewModel.roomOn {
                    Divider()

                    CollapsibleSection(
                        title: "Scenes",
                        isExpanded: $viewModel.isScenesExpanded
                    ) {
                        ScenePicker(viewModel: viewModel)
                    }
                }

                Divider()

                HStack {
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        viewModel.resetRoomSelection()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}
