import AVFoundation
import Foundation

final class FileAudioSource: AudioSource, @unchecked Sendable {
    var onSamples: (([Float]) -> Void)?
    var onFinished: (() -> Void)?

    private let url: URL
    private let readQueue = DispatchQueue(label: "transcript.filesource")
    private var stopped = false

    init(url: URL) {
        self.url = url
    }

    func start() throws {
        let file = try AVAudioFile(forReading: url)
        readQueue.async { [weak self] in
            self?.pump(file)
        }
    }

    func stop() {
        stopped = true
    }

    private func pump(_ file: AVAudioFile) {
        let format = file.processingFormat
        while stopped == false {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_000) else { break }
            guard (try? file.read(into: buffer)) != nil else { break }
            guard buffer.frameLength > 0 else { break }
            guard let data = buffer.floatChannelData else { break }
            onSamples?(Array(UnsafeBufferPointer(start: data[0], count: Int(buffer.frameLength))))
        }
        onFinished?()
    }
}
