import AppKit
import SwiftUI

enum AppComposition {
    @MainActor static let session = RecordingSession(
        microphone: ArchivingAudioSource(wrapping: PausableAudioSource(wrapping: MicCapture()), suffix: "mic"),
        auxiliarySources: [ArchivingAudioSource(wrapping: PausableAudioSource(wrapping: SystemAudioCapture()), suffix: "aux1")],
        speechToText: WhisperKitEngine(),
        speakerIdentifier: FluidAudioLabeler(),
        writer: FileTranscriptStore(engineTag: WhisperKitEngine.modelTag),
        state: FileStateStore(),
        settings: FileSettingsStore()
    )

    @MainActor static func makeBackfillSession(source: AudioSource, audioName: String) -> RecordingSession {
        RecordingSession(
            microphone: source,
            auxiliarySources: [],
            speechToText: WhisperKitEngine(),
            speakerIdentifier: FluidAudioLabeler(),
            writer: FileTranscriptStore(engineTag: WhisperKitEngine.modelTag, sourceAudio: audioName),
            state: NullStateReporter(),
            settings: FileSettingsStore()
        )
    }
}

struct NullStateReporter: StateReporter {
    func recordingStarted(livePath: String?) {}
    func recordingSaved(path: String) {}
    func paused() {}
    func idle() {}
    func exited() {}
}

@main
struct VoiceScribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuView()
        } label: {
            MenuBarIcon()
        }
        Window("VoiceScribe", id: "transcript") {
            TranscriptView()
        }
        .defaultSize(width: 480, height: 380)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var signalSources: [DispatchSourceSignal] = []
    private var backfillSession: RecordingSession?
    private var backfillSource: FileAudioSource?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installSignalHandlers()
        guard runBackfillIfRequested() == false else { return }
        FileStateStore().idle()
        AppComposition.session.preloadEngines()
        if CommandLine.arguments.contains("--record") {
            Task { await AppComposition.session.start() }
        }
    }

    private func runBackfillIfRequested() -> Bool {
        guard let flagIndex = CommandLine.arguments.firstIndex(of: "--backfill") else { return false }
        guard CommandLine.arguments.indices.contains(flagIndex + 1) else {
            print("usage: voicescribe --backfill <audio.m4a>")
            NSApp.terminate(nil)
            return true
        }
        let audio = URL(fileURLWithPath: CommandLine.arguments[flagIndex + 1])
        let source = FileAudioSource(url: audio)
        let session = AppComposition.makeBackfillSession(source: source, audioName: audio.lastPathComponent)
        backfillSource = source
        backfillSession = session
        source.onFinished = {
            Task { @MainActor in
                session.stop {
                    print(session.lines.joined(separator: "\n"))
                    NSApp.terminate(nil)
                }
            }
        }
        Task { await session.start() }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard AppComposition.session.isRecording else { return .terminateNow }
        AppComposition.session.stop {
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppComposition.session.markExited()
    }

    private func installSignalHandlers() {
        for sig in [SIGINT, SIGTERM, SIGUSR1, SIGUSR2] {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler {
                Task { @MainActor [weak self] in self?.handleSignal(sig) }
            }
            source.resume()
            signalSources.append(source)
        }
    }

    private func handleSignal(_ sig: Int32) {
        if sig == SIGUSR1 {
            Task { await AppComposition.session.start() }
            return
        }
        if sig == SIGUSR2 {
            AppComposition.session.stop()
            return
        }
        NSApp.terminate(nil)
    }
}
