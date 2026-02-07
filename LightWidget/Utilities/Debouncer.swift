import Foundation

@MainActor
final class Debouncer {
    private let duration: Duration
    private var task: Task<Void, Never>?

    init(duration: Duration = .milliseconds(200)) {
        self.duration = duration
    }

    func call(_ action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}
