import Foundation

struct FileTranscriptStore: TranscriptWriter {
    let directory: URL

    private let engineTag: String?
    private let sourceAudio: String?

    init(directory: URL? = nil, engineTag: String? = nil, sourceAudio: String? = nil) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        self.directory = directory ?? documents.appendingPathComponent("Transcript")
        self.engineTag = engineTag
        self.sourceAudio = sourceAudio
    }

    func begin() throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = Self.timestamp()
        let output = directory.appendingPathComponent("\(name).md")
        var header = "---\ndate: \(name)\nstatus: live\n"
        if let engineTag {
            header += "engine: \(engineTag)\n"
        }
        if let sourceAudio {
            header += "source_audio: \(sourceAudio)\n"
        }
        header += "---\n\n"
        try header.write(to: output, atomically: true, encoding: .utf8)
        return output
    }

    func append(_ line: String, to url: URL) {
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: Data((line + "\n").utf8))
    }

    func finalize(at url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
            .replacing("status: live\n", with: "", maxReplacements: 1)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func discard(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}
