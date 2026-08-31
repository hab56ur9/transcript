import Foundation

struct FileSettingsStore: SettingsStoring {
    private struct Settings: Codable {
        var language: String?
        var saveAudio: Bool?
        var confirmRecording: Bool?

        enum CodingKeys: String, CodingKey {
            case language
            case saveAudio = "save_audio"
            case confirmRecording = "confirm_recording"
        }
    }

    private var url: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return support
            .appendingPathComponent("Transcript")
            .appendingPathComponent("settings.json")
    }

    func loadLanguage() -> String? {
        read()?.language
    }

    func loadSaveAudio() -> Bool? {
        read()?.saveAudio
    }

    func loadConfirmRecording() -> Bool? {
        read()?.confirmRecording
    }

    func save(language: String) {
        update { $0.language = language }
    }

    func save(saveAudio: Bool) {
        update { $0.saveAudio = saveAudio }
    }

    func save(confirmRecording: Bool) {
        update { $0.confirmRecording = confirmRecording }
    }

    private func read() -> Settings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Settings.self, from: data)
    }

    private func update(_ mutate: (inout Settings) -> Void) {
        var settings = read() ?? Settings(language: nil, saveAudio: nil, confirmRecording: nil)
        mutate(&settings)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
