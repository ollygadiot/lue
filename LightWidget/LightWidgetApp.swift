import SwiftUI

@main
struct LightWidgetApp: App {
    @State private var viewModel = LightViewModel()

    var body: some Scene {
        MenuBarExtra {
            Group {
                if !viewModel.isConfigured {
                    SetupView(viewModel: viewModel)
                } else if !viewModel.isRoomSelected {
                    RoomSelectionView(viewModel: viewModel)
                } else {
                    LightPopoverView(viewModel: viewModel)
                }
            }
            .task {
                viewModel.start()
            }
        } label: {
            Image(systemName: viewModel.anyLightOn ? "lightbulb.fill" : "lightbulb")
        }
        .menuBarExtraStyle(.window)
    }
}
