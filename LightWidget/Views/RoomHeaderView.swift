import SwiftUI

struct RoomHeaderView: View {
    @Bindable var viewModel: LightViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Werkkamer")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.roomOn },
                    set: { _ in viewModel.toggleRoom() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            if viewModel.roomOn {
                HStack(spacing: 8) {
                    Image(systemName: "sun.min")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    Slider(
                        value: Binding(
                            get: { viewModel.roomBrightness },
                            set: { viewModel.setRoomBrightness($0) }
                        ),
                        in: 1...100
                    )

                    Image(systemName: "sun.max")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}
