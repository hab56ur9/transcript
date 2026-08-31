import Foundation

final class HallucinationFilter: SpeechToText {
    private let base: SpeechToText

    private static let phrases: Set<String> = [
        "감사합니다",
        "시청해주셔서감사합니다",
        "끝까지시청해주셔서감사합니다",
        "오늘도시청해주셔서감사합니다",
        "구독과좋아요부탁드립니다",
        "구독좋아요알림설정까지부탁드립니다",
        "다음영상에서만나요",
        "다음영상에서뵙겠습니다",
        "자막제공",
        "한국어자막",
        "thankyouforwatching",
        "thanksforwatching",
        "pleasesubscribe",
        "subtitlesbytheamaraorgcommunity",
    ]

    init(wrapping base: SpeechToText) {
        self.base = base
    }

    func load() async throws {
        try await base.load()
    }

    func transcribe(samples: [Float], language: String) async throws -> String {
        let text = try await base.transcribe(samples: samples, language: language)
        guard Self.isHallucination(text) else { return text }
        return ""
    }

    private static func isHallucination(_ text: String) -> Bool {
        phrases.contains(normalized(text))
    }

    private static func normalized(_ text: String) -> String {
        String(text.lowercased().unicodeScalars.filter(CharacterSet.alphanumerics.contains))
    }
}
