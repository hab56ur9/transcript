import Foundation
import Testing

@testable import Transcript

struct HallucinationFilterTests {
    private func filtered(_ text: String) async throws -> String {
        let base = FakeSpeechToText()
        base.result = text
        let filter = HallucinationFilter(wrapping: base)
        return try await filter.transcribe(samples: [], language: "ko")
    }

    @Test func dropsKnownPhrase() async throws {
        #expect(try await filtered("감사합니다") == "")
    }

    @Test func dropsPhraseDespitePunctuationAndSpacing() async throws {
        #expect(try await filtered("시청해 주셔서 감사합니다.") == "")
        #expect(try await filtered("Thank you for watching!") == "")
    }

    @Test func keepsRealSpeech() async throws {
        #expect(try await filtered("오늘 회의를 시작하겠습니다") == "오늘 회의를 시작하겠습니다")
        #expect(try await filtered("검토해 주셔서 감사합니다 다음 안건으로 넘어가죠") == "검토해 주셔서 감사합니다 다음 안건으로 넘어가죠")
    }
}
