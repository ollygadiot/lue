import SwiftUI

@main
struct LightWidgetApp: App {
    @State private var viewModel = LightViewModel()

    var body: some Scene {
        MenuBarExtra {
            Group {
                if viewModel.isConfigured {
                    LightPopoverView(viewModel: viewModel)
                } else {
                    SetupView(viewModel: viewModel)
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
