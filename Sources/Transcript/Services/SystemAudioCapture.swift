import AVFoundation
import ScreenCaptureKit

final class SystemAudioCapture: NSObject, SCStreamOutput, SCStreamDelegate, AudioSource {
    var onSamples: (([Float]) -> Void)?

    private var stream: SCStream?
    private let sampleQueue = DispatchQueue(label: "transcript.systemaudio")

    func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let display = content.displays.first else {
            throw NSError(
                domain: "Transcript",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "no display available"]
            )
        }
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = 16_000
        config.channelCount = 1
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleQueue)
        try await stream.startCapture()
        self.stream = stream
    }

    func stop() {
        guard let stream else { return }
        self.stream = nil
        Task {
            try? await stream.stopCapture()
        }
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, let samples = sampleBuffer.floatSamples() else { return }
        onSamples?(samples)
    }
}

extension CMSampleBuffer {
    func floatSamples() -> [Float]? {
        guard let description = formatDescription?.audioStreamBasicDescription else { return nil }
        guard description.mFormatID == kAudioFormatLinearPCM else { return nil }
        guard let blockBuffer = dataBuffer else { return nil }
        guard let data = try? blockBuffer.dataBytes() else { return nil }
        return data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }
}
