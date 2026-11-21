import Foundation
import Testing

@testable import Transcript

final class CountingAudioSource: AudioSource, @unchecked Sendable {
    var onSamples: (([Float]) -> Void)?

    private let startDelay: Duration
    private let lock = NSLock()
    private var startCount = 0
    private var stopCount = 0
    private var inFlight = 0
    private var maxInFlight = 0
    private var capturing = false

    init(startDelay: Duration = .zero) {
        self.startDelay = startDelay
    }

    var starts: Int { lock.withLock { startCount } }
    var stops: Int { lock.withLock { stopCount } }
    var peakStartsInFlight: Int { lock.withLock { maxInFlight } }
    var isCapturing: Bool { lock.withLock { capturing } }

    func start() async throws {
        lock.withLock {
            startCount += 1
            inFlight += 1
            maxInFlight = max(maxInFlight, inFlight)
        }
        try await Task.sleep(for: startDelay)
        lock.withLock {
            inFlight -= 1
            capturing = true
        }
    }

    func stop() {
        lock.withLock {
            stopCount += 1
            capturing = false
        }
    }
}

struct StallRecoveringAudioSourceTests {
    @Test func stalledSourceIsRestarted() async throws {
        let source = CountingAudioSource()
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(50))

        try await recovering.start()
        source.onSamples?([0])
        try await Task.sleep(for: .milliseconds(300))
        recovering.stop()

        #expect(source.starts >= 2)
    }

    @Test func sourceThatNeverFlowedIsLeftAlone() async throws {
        let source = CountingAudioSource()
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(50))

        try await recovering.start()
        try await Task.sleep(for: .milliseconds(300))
        recovering.stop()

        #expect(source.starts == 1)
    }

    @Test func flowingSourceIsLeftAlone() async throws {
        let source = CountingAudioSource()
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(500))

        try await recovering.start()
        for _ in 0..<10 {
            source.onSamples?([0])
            try await Task.sleep(for: .milliseconds(100))
        }
        recovering.stop()

        #expect(source.starts == 1)
        #expect(source.stops == 1)
    }

    @Test func samplesPassThrough() async throws {
        let source = CountingAudioSource()
        let recovering = StallRecoveringAudioSource(wrapping: source)
        var received: [Float] = []
        recovering.onSamples = { received += $0 }

        try await recovering.start()
        source.onSamples?([0.25, 0.5])
        recovering.stop()

        #expect(received == [0.25, 0.5])
    }

    @Test func stoppedSourceIsNotRestarted() async throws {
        let source = CountingAudioSource()
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(50))

        try await recovering.start()
        source.onSamples?([0])
        recovering.stop()
        try await Task.sleep(for: .milliseconds(200))

        #expect(source.starts == 1)
    }

    @Test func stopDuringStartLeavesSourceStopped() async throws {
        let source = CountingAudioSource(startDelay: .milliseconds(100))
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(50))

        let starting = Task { try await recovering.start() }
        try await Task.sleep(for: .milliseconds(20))
        recovering.stop()
        try await starting.value
        try await Task.sleep(for: .milliseconds(200))

        #expect(source.isCapturing == false)
        #expect(source.starts == 1)
    }

    @Test func slowRestartsNeverOverlap() async throws {
        let source = CountingAudioSource(startDelay: .milliseconds(100))
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(30))

        try await recovering.start()
        source.onSamples?([0])
        try await Task.sleep(for: .milliseconds(400))
        recovering.stop()

        #expect(source.peakStartsInFlight == 1)
    }

    @Test func stopDuringRestartLeavesSourceStopped() async throws {
        let source = CountingAudioSource(startDelay: .milliseconds(150))
        let recovering = StallRecoveringAudioSource(wrapping: source, timeout: .milliseconds(30))

        let starting = Task { try await recovering.start() }
        try await starting.value
        source.onSamples?([0])
        try await Task.sleep(for: .milliseconds(80))
        recovering.stop()
        try await Task.sleep(for: .milliseconds(300))

        #expect(source.isCapturing == false)
    }
}
