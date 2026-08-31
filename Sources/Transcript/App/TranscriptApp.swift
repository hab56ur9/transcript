import AppKit
import SwiftUI

enum AppComposition {
    @MainActor static let session = RecordingSession(
        microphone: ArchivingAudioSource(wrapping: PausableAudioSource(wrapping: MicCapture()), suffix: "mic"),
        auxiliarySources: [ArchivingAudioSource(wrapping: PausableAudioSource(wrapping: SystemAudioCapture()), suffix: "aux1")],
        speechToText: HallucinationFilter(wrapping: WhisperKitEngine()),
        speakerIdentifier: FluidAudioLabeler(),
        writer: FileTranscriptStore(engineTag: WhisperKitEngine.modelTag),
        state: FileStateStore(),
        settings: FileSettingsStore()
    )

    @MainActor static func makeBackfillSession(source: AudioSource, audioName: String) -> RecordingSession {
        RecordingSession(
            microphone: source,
            auxiliarySources: [],
            speechToText: HallucinationFilter(wrapping: WhisperKitEngine()),
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
struct TranscriptApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuView()
        } label: {
            MenuBarIcon()
        }
        Window("Transcript", id: "transcript") {
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
            requestSessionStart()
        }
    }

    private func runBackfillIfRequested() -> Bool {
        guard let flagIndex = CommandLine.arguments.firstIndex(of: "--backfill") else { return false }
        guard CommandLine.arguments.indices.contains(flagIndex + 1) else {
            print("usage: transcript --backfill <audio.m4a>")
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

    private var terminateRequested = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard AppComposition.session.isBusy else { return .terminateNow }
        guard terminateRequested == false else { return .terminateCancel }
        terminateRequested = true
        AppComposition.session.stop {
            NSApp.terminate(nil)
        }
        return .terminateCancel
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

    private func requestSessionStart() {
        guard FileSettingsStore().loadConfirmRecording() ?? true else {
            Task { await AppComposition.session.start() }
            return
        }
        guard AlertApprover().requestApproval() else { return }
        Task { await AppComposition.session.start() }
    }

    private func handleSignal(_ sig: Int32) {
        if sig == SIGUSR1 {
            requestSessionStart()
            return
        }
        if sig == SIGUSR2 {
            AppComposition.session.stop()
            return
        }
        NSApp.terminate(nil)
    }
}
