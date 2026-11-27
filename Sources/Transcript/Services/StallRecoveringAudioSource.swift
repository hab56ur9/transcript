import Foundation

final class StallRecoveringAudioSource: AudioSource, @unchecked Sendable {
    var onSamples: (([Float]) -> Void)?

    private let wrapped: AudioSource
    private let timeout: Duration
    private let clock = ContinuousClock()
    private let watchQueue = DispatchQueue(label: "transcript.stallwatch")
    private var timer: DispatchSourceTimer?
    private var lastSampleAt: ContinuousClock.Instant
    private var flowed = false
    private var running = false
    private var restarting = false

    init(wrapping wrapped: AudioSource, timeout: Duration = .seconds(3)) {
        self.wrapped = wrapped
        self.timeout = timeout
        self.lastSampleAt = clock.now
        wrapped.onSamples = { [weak self] samples in
            guard let self else { return }
            self.watchQueue.async {
                self.lastSampleAt = self.clock.now
                self.flowed = true
            }
            self.onSamples?(samples)
        }
    }

    func start() async throws {
        watchQueue.sync {
            timer?.cancel()
            timer = nil
            running = true
            flowed = false
        }
        try await wrapped.start()
        let stoppedMeanwhile = watchQueue.sync { running == false }
        guard stoppedMeanwhile == false else {
            wrapped.stop()
            return
        }
        watchQueue.sync {
            lastSampleAt = clock.now
            let timer = DispatchSource.makeTimerSource(queue: watchQueue)
            timer.schedule(deadline: .now() + timeout.timeInterval, repeating: timeout.timeInterval)
            timer.setEventHandler { [weak self] in self?.restartIfStalled() }
            timer.resume()
            self.timer = timer
        }
    }

    func stop() {
        watchQueue.sync {
            running = false
            timer?.cancel()
            timer = nil
        }
        wrapped.stop()
    }

    func pause() {
        wrapped.pause()
    }

    func resume() {
        wrapped.resume()
    }

    private var stalled: Bool {
        lastSampleAt.duration(to: clock.now) >= timeout
    }

    private func restartIfStalled() {
        guard restarting == false else { return }
        guard flowed else { return }
        guard stalled else { return }
        restarting = true
        Task { [weak self] in
            guard let self else { return }
            self.wrapped.stop()
            try? await self.wrapped.start()
            let stoppedMeanwhile = self.watchQueue.sync {
                self.restarting = false
                self.lastSampleAt = self.clock.now
                return self.running == false
            }
            guard stoppedMeanwhile else { return }
            self.wrapped.stop()
        }
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}
