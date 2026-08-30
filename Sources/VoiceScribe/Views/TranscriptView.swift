import SwiftUI

struct TranscriptView: View {
    var body: some View {
        let session = AppComposition.session
        VStack(spacing: 0) {
            if session.isRecording {
                RecordingControls(session: session)
                Divider()
            }
            TabView {
                TranscriptFeed(session: session)
                    .tabItem { Text("Transcript") }
                MemoPad(session: session)
                    .tabItem { Text("Memo") }
            }
        }
    }
}

struct MemoPad: View {
    let session: RecordingSession

    @State private var text = ""
    @State private var loadedURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            if session.memoURL == nil {
                Text("Memo becomes available when a recording starts.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let memoURL = session.memoURL {
                TextEditor(text: $text)
                    .font(.system(size: 13))
                    .padding(4)
                    .onAppear { load(from: memoURL) }
                    .onChange(of: session.memoURL) { _, changedURL in
                        guard let changedURL else { return }
                        load(from: changedURL)
                    }
                    .onChange(of: text) { _, updated in
                        try? updated.write(to: memoURL, atomically: true, encoding: .utf8)
                    }
            }
        }
    }

    private func load(from url: URL) {
        guard loadedURL != url else { return }
        loadedURL = url
        text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}

struct RecordingControls: View {
    let session: RecordingSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.isPaused ? "pause.circle.fill" : "record.circle")
                .foregroundStyle(session.isPaused ? Color.orange : Color.red)
            Text(session.elapsedText)
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
            if session.isPaused {
                Text("Paused")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                session.togglePause()
            } label: {
                Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
            }
            .help(session.isPaused ? "Resume" : "Pause")
            Button {
                session.stop()
            } label: {
                Image(systemName: "stop.fill")
            }
            .help("Stop and save")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct TranscriptFeed: View {
    let session: RecordingSession

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(session.lines.indices, id: \.self) { index in
                        Text(session.lines[index])
                            .font(.system(size: 13))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)
                    }
                }
                .padding(12)
                .textSelection(.enabled)
            }
            .onChange(of: session.lines.count) { _, _ in
                if let last = session.lines.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }
}
