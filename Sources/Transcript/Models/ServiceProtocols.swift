import Foundation

protocol AudioSource: AnyObject {
    var onSamples: (([Float]) -> Void)? { get set }
    func start() async throws
    func stop()
    func pause()
    func resume()
}

extension AudioSource {
    func pause() {}
    func resume() {}
}

protocol SpeechToText: AnyObject {
    func load() async throws
    func transcribe(samples: [Float], language: String) async throws -> String
}

protocol SettingsStoring {
    func loadLanguage() -> String?
    func loadSaveAudio() -> Bool?
    func save(language: String)
    func save(saveAudio: Bool)
}


protocol SpeakerIdentifying: AnyObject {
    func load() async throws
    func label(for samples: [Float]) async -> String?
}

protocol TranscriptWriter {
    func begin() throws -> URL
    func append(_ line: String, to url: URL)
    func finalize(at url: URL) throws
    func discard(_ url: URL)
}

protocol StateReporter {
    func recordingStarted(livePath: String?)
    func recordingSaved(path: String)
    func paused()
    func idle()
    func exited()
}
