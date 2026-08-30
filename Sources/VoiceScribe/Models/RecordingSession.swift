import Foundation
import Observation

@MainActor
@Observable
final class RecordingSession {
    private(set) var isRecording = false
    private(set) var lines: [String] = []
    private(set) var language: String

    var isBusy: Bool { isRecording || isFinishing }

    @ObservationIgnored private let microphone: AudioSource
    @ObservationIgnored private let auxiliarySources: [AudioSource]
    @ObservationIgnored private let speechToText: SpeechToText
    @ObservationIgnored private let speakerIdentifier: SpeakerIdentifying
    @ObservationIgnored private let writer: TranscriptWriter
    @ObservationIgnored private let state: StateReporter
    @ObservationIgnored private let settings: SettingsStoring

    @ObservationIgnored nonisolated private let audioQueue = DispatchQueue(label: "voicescribe.chunking")
    @ObservationIgnored nonisolated(unsafe) private var splitters: [ChunkSplitter] = []
    @ObservationIgnored private var sessionURL: URL?
    @ObservationIgnored private var utteranceCount = 0
    @ObservationIgnored private var lastSpeaker = "화자1"
    @ObservationIgnored private var serialTask: Task<Void, Never>?
    @ObservationIgnored private var isFinishing = false
    @ObservationIgnored private var finishWaiters: [() -> Void] = []

    init(
        microphone: AudioSource,
        auxiliarySources: [AudioSource],
        speechToText: SpeechToText,
        speakerIdentifier: SpeakerIdentifying,
        writer: TranscriptWriter,
        state: StateReporter,
        settings: SettingsStoring
    ) {
        self.microphone = microphone
        self.auxiliarySources = auxiliarySources
        self.speechToText = speechToText
        self.speakerIdentifier = speakerIdentifier
        self.writer = writer
        self.state = state
        self.settings = settings
        self.language = settings.loadLanguage() ?? "ko"
        wire()
    }

    func setLanguage(_ code: String) {
        language = code
        settings.save(language: code)
    }

    func preloadEngines() {
        Task { [speechToText] in
            try? await speechToText.load()
        }
        Task { [speakerIdentifier] in
            try? await speakerIdentifier.load()
        }
    }

    func start() async {
        guard isBusy == false else { return }
        do {
            try await microphone.start()
        } catch {
            lines.append("⚠️ 마이크 시작 실패: \(error.localizedDescription)")
            return
        }
        isRecording = true
        beginTranscript()
        startAuxiliarySources()
    }

    func stop(onFinished: (() -> Void)? = nil) {
        guard isRecording else {
            notifyWhenFinished(onFinished)
            return
        }
        isFinishing = true
        microphone.stop()
        auxiliarySources.forEach { $0.stop() }
        isRecording = false
        audioQueue.async { [weak self] in
            guard let self else {
                onFinished?()
                return
            }
            self.splitters.forEach { $0.flush() }
            Task { @MainActor in self.finishTranscript(onFinished: onFinished) }
        }
    }

    func markExited() {
        state.exited()
    }

    private func wire() {
        for source in [microphone] + auxiliarySources {
            let splitter = ChunkSplitter()
            splitter.onChunk = { [weak self] chunk in
                Task { @MainActor in self?.enqueue(chunk: chunk) }
            }
            source.onSamples = { [weak self, splitter] samples in
                self?.audioQueue.async { splitter.feed(samples) }
            }
            splitters.append(splitter)
        }
    }

    private func notifyWhenFinished(_ onFinished: (() -> Void)?) {
        guard let onFinished else { return }
        guard isFinishing else {
            onFinished()
            return
        }
        finishWaiters.append(onFinished)
    }

    private func enqueue(chunk: [Float]) {
        let previous = serialTask
        serialTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            guard let (speaker, text) = await self.recognize(chunk) else { return }
            self.record(speaker: speaker, text: text)
        }
    }

    private func recognize(_ chunk: [Float]) async -> (speaker: String?, text: String)? {
        async let speaker = speakerIdentifier.label(for: chunk)
        guard let text = try? await speechToText.transcribe(samples: chunk, language: language) else { return nil }
        guard text.isEmpty == false else { return nil }
        return (await speaker, text)
    }

    private func record(speaker: String?, text: String) {
        let utterance = Utterance(speaker: speaker ?? lastSpeaker, text: text)
        lastSpeaker = utterance.speaker
        utteranceCount += 1
        if let sessionURL {
            writer.append(utterance.line, to: sessionURL)
        }
        lines.append(utterance.line)
    }

    private func beginTranscript() {
        utteranceCount = 0
        lines.removeAll()
        sessionURL = try? writer.begin()
        state.recordingStarted(livePath: sessionURL?.path)
        if let sessionURL {
            lines.append("📝 실시간 전사: \(sessionURL.path)")
        }
    }

    private func startAuxiliarySources() {
        for source in auxiliarySources {
            Task { [weak self] in
                do {
                    try await source.start()
                } catch {
                    self?.lines.append("⚠️ 보조 오디오 캡처 실패, 마이크만 녹음: \(error.localizedDescription)")
                }
            }
        }
    }

    private func finishTranscript(onFinished: (() -> Void)?) {
        let pending = serialTask
        Task { [weak self] in
            await pending?.value
            guard let self else {
                onFinished?()
                return
            }
            self.closeSessionFile()
            self.sessionURL = nil
            self.isFinishing = false
            onFinished?()
            self.finishWaiters.forEach { $0() }
            self.finishWaiters.removeAll()
        }
    }

    private func closeSessionFile() {
        guard let sessionURL else {
            state.idle()
            return
        }
        guard utteranceCount > 0 else {
            writer.discard(sessionURL)
            state.idle()
            return
        }
        saveTranscript(at: sessionURL)
    }

    private func saveTranscript(at url: URL) {
        do {
            try writer.finalize(at: url)
            state.recordingSaved(path: url.path)
            lines.append("💾 저장됨: \(url.path)")
        } catch {
            state.idle()
            lines.append("⚠️ 저장 실패: \(error.localizedDescription)")
        }
    }

}
