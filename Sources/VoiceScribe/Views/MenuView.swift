import AppKit
import SwiftUI

struct MenuBarIcon: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let session = AppComposition.session
        Image(systemName: session.isRecording ? "mic.fill" : "mic")
            .onAppear {
                guard session.isRecording else { return }
                showTranscript()
            }
            .onChange(of: session.isRecording) { _, isRecording in
                guard isRecording else {
                    NSSound(named: "Pop")?.play()
                    return
                }
                NSSound(named: "Glass")?.play()
                showTranscript()
            }
    }

    private func showTranscript() {
        openWindow(id: "transcript")
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct MenuView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let session = AppComposition.session
        Button(session.isRecording ? "Stop Recording" : "Start Recording") {
            toggleRecording(session)
        }
        .keyboardShortcut("r")

        Button("Show Transcript") {
            openTranscript()
        }
        .keyboardShortcut("t")

        Picker("Language", selection: Binding(
            get: { session.language },
            set: { session.setLanguage($0) }
        )) {
            Text("한국어").tag("ko")
            Text("English").tag("en")
        }

        Toggle("Save Audio", isOn: Binding(
            get: { FileSettingsStore().loadSaveAudio() ?? true },
            set: { FileSettingsStore().save(saveAudio: $0) }
        ))

        Divider()

        Button("Quit VoiceScribe") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func toggleRecording(_ session: RecordingSession) {
        if session.isRecording {
            session.stop()
            return
        }
        openTranscript()
        Task { await session.start() }
    }

    private func openTranscript() {
        openWindow(id: "transcript")
        NSApp.activate(ignoringOtherApps: true)
    }
}
