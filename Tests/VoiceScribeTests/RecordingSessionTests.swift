import Foundation
import Testing

@testable import VoiceScribe

final class FakeAudioSource: AudioSource {
    var onSamples: (([Float]) -> Void)?
    private(set) var started = false
    private(set) var stopped = false

    func start() throws {
        started = true
    }

    func stop() {
        stopped = true
    }
}

final class FakeSpeechToText: SpeechToText {
    var result = "안녕하세요"
    private(set) var lastLanguage: String?

    func load() async throws {}

    func transcribe(samples: [Float], language: String) async throws -> String {
        lastLanguage = language
        return result
    }
}

final class FakeSettingsStore: SettingsStoring {
    var storedLanguage: String?
    var storedSaveAudio: Bool?

    func loadLanguage() -> String? {
        storedLanguage
    }

    func loadSaveAudio() -> Bool? {
        storedSaveAudio
    }

    func save(language: String) {
        storedLanguage = language
    }

    func save(saveAudio: Bool) {
        storedSaveAudio = saveAudio
    }
}

final class FakeSpeakerIdentifying: SpeakerIdentifying {
    var result: String? = "화자1"

    func load() async throws {}

    func label(for samples: [Float]) async -> String? {
        result
    }
}

final class FakeTranscriptWriter: TranscriptWriter {
    let url = URL(fileURLWithPath: "/tmp/voicescribe-test.md")
    private(set) var appended: [String] = []
    private(set) var finalized = false
    private(set) var discarded = false

    func begin() throws -> URL {
        url
    }

    func append(_ line: String, to url: URL) {
        appended.append(line)
    }

    func finalize(at url: URL) throws {
        finalized = true
    }

    func discard(_ url: URL) {
        discarded = true
    }
}

final class FakeStateReporter: StateReporter {
    private(set) var transitions: [String] = []
    private(set) var savedPath: String?

    func recordingStarted(livePath: String?) {
        transitions.append("recording")
    }

    func recordingSaved(path: String) {
        transitions.append("saved")
        savedPath = path
    }

    func idle() {
        transitions.append("idle")
    }

    func exited() {
        transitions.append("exited")
    }
}

@Suite @MainActor struct RecordingSessionTests {
    private func makeSession(
        source: FakeAudioSource = FakeAudioSource(),
        speechToText: FakeSpeechToText = FakeSpeechToText(),
        identifier: FakeSpeakerIdentifying = FakeSpeakerIdentifying(),
        writer: FakeTranscriptWriter = FakeTranscriptWriter(),
        state: FakeStateReporter = FakeStateReporter(),
        settings: FakeSettingsStore = FakeSettingsStore()
    ) -> RecordingSession {
        RecordingSession(
            microphone: source,
            auxiliarySources: [],
            speechToText: speechToText,
            speakerIdentifier: identifier,
            writer: writer,
            state: state,
            settings: settings
        )
    }

    private func stopAndWait(_ session: RecordingSession) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            session.stop { continuation.resume() }
        }
    }

    @Test func emptySessionIsDiscarded() async {
        let writer = FakeTranscriptWriter()
        let state = FakeStateReporter()
        let session = makeSession(writer: writer, state: state)

        await session.start()
        await stopAndWait(session)

        #expect(writer.discarded)
        #expect(writer.finalized == false)
        #expect(state.transitions == ["recording", "idle"])
    }

    @Test func spokenSessionIsAppendedAndFinalized() async {
        let source = FakeAudioSource()
        let writer = FakeTranscriptWriter()
        let state = FakeStateReporter()
        let session = makeSession(source: source, writer: writer, state: state)

        await session.start()
        source.onSamples?([Float](repeating: 0.5, count: 8_000))
        await stopAndWait(session)

        #expect(writer.appended == ["[화자1] 안녕하세요"])
        #expect(writer.finalized)
        #expect(state.transitions == ["recording", "saved"])
        #expect(state.savedPath == writer.url.path)
        #expect(source.stopped)
    }

    @Test func stopWithoutStartFinishesImmediately() async {
        let session = makeSession()
        await stopAndWait(session)
    }

    @Test func languageDefaultsToKoreanAndPersistsOnChange() {
        let settings = FakeSettingsStore()
        let session = makeSession(settings: settings)

        #expect(session.language == "ko")

        session.setLanguage("en")

        #expect(session.language == "en")
        #expect(settings.storedLanguage == "en")
    }

    @Test func storedLanguageIsUsedForTranscription() async {
        let source = FakeAudioSource()
        let speechToText = FakeSpeechToText()
        let settings = FakeSettingsStore()
        settings.storedLanguage = "en"
        let session = makeSession(source: source, speechToText: speechToText, settings: settings)

        await session.start()
        source.onSamples?([Float](repeating: 0.5, count: 8_000))
        await stopAndWait(session)

        #expect(speechToText.lastLanguage == "en")
    }

    @Test func unknownSpeakerFallsBackToLastSpeaker() async {
        let source = FakeAudioSource()
        let writer = FakeTranscriptWriter()
        let identifier = FakeSpeakerIdentifying()
        identifier.result = nil
        let session = makeSession(source: source, identifier: identifier, writer: writer)

        await session.start()
        source.onSamples?([Float](repeating: 0.5, count: 8_000))
        await stopAndWait(session)

        #expect(writer.appended == ["[화자1] 안녕하세요"])
    }
}
