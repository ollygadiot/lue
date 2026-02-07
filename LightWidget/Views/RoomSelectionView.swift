import SwiftUI

struct RoomSelectionView: View {
    @Bindable var viewModel: LightViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "door.left.hand.open")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Select a Room")
                .font(.headline)

            if viewModel.isLoadingRooms {
                ProgressView("Loading rooms...")
            } else if viewModel.availableRooms.isEmpty {
                VStack(spacing: 8) {
                    Text("No rooms found")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Retry") {
                        viewModel.loadAvailableRooms()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(viewModel.availableRooms) { room in
                        Button {
                            viewModel.selectRoom(room)
                        } label: {
                            HStack {
                                Text(room.metadata.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 280)
        .task {
            viewModel.loadAvailableRooms()
        }
    }
}
