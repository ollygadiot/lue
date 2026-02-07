import SwiftUI

struct LightRowView: View {
    let light: HueLight
    @Bindable var viewModel: LightViewModel

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(light.on.on ? Color.yellow : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)

            Text(light.metadata.name)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            if light.on.on, light.dimming != nil {
                Slider(
                    value: Binding(
                        get: { light.dimming?.brightness ?? 0 },
                        set: { viewModel.setLightBrightness(light, brightness: $0) }
                    ),
                    in: 1...100
                )
                .frame(width: 80)
            }

            Toggle("", isOn: Binding(
                get: { light.on.on },
                set: { _ in viewModel.toggleLight(light) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.mini)
        }
    }
}
