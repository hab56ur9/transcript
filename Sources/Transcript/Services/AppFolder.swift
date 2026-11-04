import Foundation

enum AppFolder {
    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Transcript"
}
