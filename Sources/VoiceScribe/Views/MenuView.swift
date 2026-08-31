import AppKit
import SwiftUI

struct MenuBarIcon: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let session = AppComposition.session
        Image(systemName: iconName(for: session))
            .foregroundStyle(iconColor(for: session))
        .onAppear {
            guard session.isRecording else { return }
            showTranscript()
        }
        .onChange(of: session.isRecording) { _, isRecording in
            guard isRecording else { return }
            showTranscript()
        }
    }

    private func iconName(for session: RecordingSession) -> String {
        guard session.isRecording else { return "mic" }
        guard session.isPaused == false else { return "mic.slash" }
        return "mic.fill"
    }

    private func iconColor(for session: RecordingSession) -> Color {
        guard session.isRecording else { return .primary }
        guard session.isPaused == false else { return .orange }
        return .red
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

        if session.isRecording {
            Label(statusText(for: session), systemImage: session.isPaused ? "mic.slash" : "mic.fill")
            Divider()
        }

        Button {
            toggleRecording(session)
        } label: {
            Label(session.isRecording ? "Stop" : "Record", systemImage: session.isRecording ? "stop.fill" : "record.circle")
        }
        .keyboardShortcut("r")

        if session.isRecording {
            Button {
                session.togglePause()
            } label: {
                Label(session.isPaused ? "Resume" : "Pause", systemImage: session.isPaused ? "play.fill" : "pause.fill")
            }
            .keyboardShortcut("p")
        }

        Button {
            openTranscript()
        } label: {
            Label("Show Transcript", systemImage: "text.alignleft")
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

        Toggle("Ask Before Recording", isOn: Binding(
            get: { FileSettingsStore().loadConfirmRecording() ?? true },
            set: { FileSettingsStore().save(confirmRecording: $0) }
        ))

        Divider()

        Button("Quit VoiceScribe") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func statusText(for session: RecordingSession) -> String {
        guard session.isPaused else { return "\(session.elapsedText) · Recording" }
        return "\(session.elapsedText) · Paused"
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
