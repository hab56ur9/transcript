import Foundation

final class PausableAudioSource: AudioSource, @unchecked Sendable {
    var onSamples: (([Float]) -> Void)?

    private let wrapped: AudioSource
    private var gateClosed = false

    init(wrapping wrapped: AudioSource) {
        self.wrapped = wrapped
        wrapped.onSamples = { [weak self] samples in
            guard let self else { return }
            guard self.gateClosed == false else { return }
            self.onSamples?(samples)
        }
    }

    func start() async throws {
        gateClosed = false
        try await wrapped.start()
    }

    func stop() {
        wrapped.stop()
    }

    func pause() {
        gateClosed = true
    }

    func resume() {
        gateClosed = false
    }
}
