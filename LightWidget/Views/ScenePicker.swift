import SwiftUI

struct ScenePicker: View {
    @Bindable var viewModel: LightViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scenes")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.sortedScenes) { scene in
                    SceneButton(
                        name: scene.metadata.name,
                        isActive: viewModel.activeSceneId == scene.id
                    ) {
                        viewModel.activateScene(scene)
                    }
                }
            }
        }
    }
}

private struct SceneButton: View {
    let name: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isActive ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
