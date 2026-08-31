import AVFoundation
import Foundation

final class ArchivingAudioSource: AudioSource, @unchecked Sendable {
    var onSamples: (([Float]) -> Void)?

    private let wrapped: AudioSource
    private let suffix: String
    private let directory: URL
    private let archiveQueue = DispatchQueue(label: "transcript.archive")
    private var file: AVAudioFile?
    private let pcmFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!

    init(wrapping wrapped: AudioSource, suffix: String) {
        self.wrapped = wrapped
        self.suffix = suffix
        self.directory = FileTranscriptStore().directory
        wrapped.onSamples = { [weak self] samples in
            self?.archiveQueue.async { self?.archive(samples) }
            self?.onSamples?(samples)
        }
    }

    func start() async throws {
        try await wrapped.start()
        guard FileSettingsStore().loadSaveAudio() ?? true else { return }
        archiveQueue.async { [weak self] in
            self?.file = self?.makeFile()
        }
    }

    func stop() {
        wrapped.stop()
        archiveQueue.async { [weak self] in
            self?.file = nil
        }
    }

    func pause() {
        wrapped.pause()
    }

    func resume() {
        wrapped.resume()
    }

    private func makeFile() -> AVAudioFile? {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(FileTranscriptStore.timestamp()).\(suffix).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 32_000,
        ]
        return try? AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
    }

    private func archive(_ samples: [Float]) {
        guard let file else { return }
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: pcmFormat,
            frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            guard let baseAddress = source.baseAddress else { return }
            buffer.floatChannelData?[0].update(from: baseAddress, count: samples.count)
        }
        try? file.write(from: buffer)
    }
}
