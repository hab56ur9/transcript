import AVFoundation

final class MicCapture: AudioSource {
    var onSamples: (([Float]) -> Void)?

    private let engine = AVAudioEngine()
    private var resampler: AudioResampler?

    func start() throws {
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        resampler = AudioResampler(from: inputFormat)
        input.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            guard let samples = self.resampler?.resample(buffer) else { return }
            self.onSamples?(samples)
        }
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        resampler = nil
    }
}
