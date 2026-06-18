import Foundation

enum WordGuessMatcher {
    static func matches(_ guess: String, secret: String) -> Bool {
        normalize(guess) == normalize(secret)
    }

    static func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
