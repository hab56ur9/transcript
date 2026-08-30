import Foundation

final class ChunkSplitter: @unchecked Sendable {
    var onChunk: (([Float]) -> Void)?

    private let frameSize = 1_600
    private let silenceThreshold: Float = 0.01
    private let silenceFramesToSplit = 7
    private let minSpeechFrames = 3
    private let maxChunkSamples = 160_000

    private var buffer: [Float] = []
    private var frame: [Float] = []
    private var silentFrames = 0
    private var speechFrames = 0

    func feed(_ samples: [Float]) {
        for sample in samples {
            frame.append(sample)
            if frame.count == frameSize {
                processFrame()
            }
        }
    }

    func flush() {
        buffer.append(contentsOf: frame)
        frame.removeAll()
        emit()
        reset()
    }

    private var utteranceEnded: Bool {
        guard speechFrames > 0 else { return false }
        return silentFrames >= silenceFramesToSplit
    }

    private func processFrame() {
        let rms = (frame.reduce(0) { $0 + $1 * $1 } / Float(frameSize)).squareRoot()
        buffer.append(contentsOf: frame)
        frame.removeAll()
        updateCounters(rms: rms)

        if utteranceEnded {
            emit()
            reset()
            return
        }
        if buffer.count >= maxChunkSamples {
            emit()
            reset()
            return
        }
        trimIdleBuffer()
    }

    private func updateCounters(rms: Float) {
        if rms < silenceThreshold {
            silentFrames += 1
            return
        }
        silentFrames = 0
        speechFrames += 1
    }

    private func trimIdleBuffer() {
        guard speechFrames == 0 else { return }
        let trailingSilenceWindow = frameSize * silenceFramesToSplit
        guard buffer.count > trailingSilenceWindow + frameSize else { return }
        buffer.removeFirst(buffer.count - trailingSilenceWindow)
    }

    private func emit() {
        guard speechFrames >= minSpeechFrames else { return }
        onChunk?(buffer)
    }

    private func reset() {
        buffer.removeAll()
        silentFrames = 0
        speechFrames = 0
    }
}
