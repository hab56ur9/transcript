import AVFoundation

final class MicCapture: AudioSource {
    var onSamples: (([Float]) -> Void)?

    private var engine: AVAudioEngine?
    private var resampler: AudioResampler?

    func start() throws {
        let engine = AVAudioEngine()
        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard inputFormat.sampleRate > 0 else { throw noInputDevice }
        guard inputFormat.channelCount > 0 else { throw noInputDevice }
        resampler = AudioResampler(from: inputFormat)
        input.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            guard let samples = self.resampler?.resample(buffer) else { return }
            self.onSamples?(samples)
        }
        engine.prepare()
        try engine.start()
        self.engine = engine
    }

    func stop() {
        guard let engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
        resampler = nil
    }

    private var noInputDevice: NSError {
        NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioHardwareBadDeviceError))
    }
}
