import Foundation

@MainActor
@Observable
final class TimerService {
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning = false

    private var timerTask: Task<Void, Never>?

    func start(
        durationSeconds: Int,
        onTick: @escaping () -> Void = {},
        onComplete: @escaping () -> Void
    ) {
        stop()
        remainingSeconds = durationSeconds
        isRunning = true

        timerTask = Task {
            while remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remainingSeconds -= 1
                onTick()
            }

            guard !Task.isCancelled else { return }
            isRunning = false
            onComplete()
        }
    }

    func stop() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
