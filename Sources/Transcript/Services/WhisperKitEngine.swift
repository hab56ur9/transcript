import Foundation
import WhisperKit

actor WhisperKitEngine: SpeechToText {
    static let modelTag = "openai_whisper-large-v3-v20240930"

    private var loadTask: Task<WhisperKit, Error>?

    func load() async throws {
        _ = try await instance()
    }

    func transcribe(samples: [Float], language: String) async throws -> String {
        let kit = try await instance()
        var options = DecodingOptions()
        options.language = language
        options.task = .transcribe
        let results = try await kit.transcribe(audioArray: samples, decodeOptions: options)
        return results.map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func instance() async throws -> WhisperKit {
        let task = loadTask ?? Task {
            try await WhisperKit(WhisperKitConfig(model: Self.modelTag))
        }
        loadTask = task
        return try await task.value
    }
}
