import Foundation

enum WordGuessMatcher {
    static func matches(_ guess: String, secret: String) -> Bool {
        normalize(guess) == normalize(secret)
    }

    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let lettersAndDigits = folded.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(lettersAndDigits))
    }
}
