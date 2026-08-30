import Foundation

struct FileStateStore: StateReporter {
    private struct AppState: Codable {
        var status: String
        var liveTranscript: String?
        var lastTranscript: String?
        var updatedAt: String

        enum CodingKeys: String, CodingKey {
            case status
            case liveTranscript = "live_transcript"
            case lastTranscript = "last_transcript"
            case updatedAt = "updated_at"
        }
    }

    private var url: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return support
            .appendingPathComponent("VoiceScribe")
            .appendingPathComponent("state.json")
    }

    func recordingStarted(livePath: String?) {
        update { state in
            state.status = "recording"
            state.liveTranscript = livePath
        }
    }

    func recordingSaved(path: String) {
        update { state in
            state.status = "idle"
            state.liveTranscript = nil
            state.lastTranscript = path
        }
    }

    func idle() {
        update { state in
            state.status = "idle"
            state.liveTranscript = nil
        }
    }

    func exited() {
        update { state in
            state.status = "exited"
            state.liveTranscript = nil
        }
    }

    private func update(_ mutate: (inout AppState) -> Void) {
        var state = read() ?? AppState(status: "idle", liveTranscript: nil, lastTranscript: nil, updatedAt: "")
        mutate(&state)
        state.updatedAt = ISO8601DateFormatter().string(from: Date())
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func read() -> AppState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppState.self, from: data)
    }
}
