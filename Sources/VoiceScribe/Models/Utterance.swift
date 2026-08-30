import Foundation

struct Utterance {
    let speaker: String
    let text: String

    var line: String {
        "[\(speaker)] \(text)"
    }
}
