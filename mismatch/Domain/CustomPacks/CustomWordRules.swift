import Foundation

// Pair and title checks for generated packs. https://github.com/kotinarupali/mismatch-ios/issues/31
enum CustomWordRules {
    static let maxCount = 40
    static let maxTitleLength = 40
    static let maxPromptLength = 80
    static let maxWordLength = 48
    static let reservedTitles = [
        "general",
        "hollywood movies & series",
        "indian pop culture",
        "pop culture",
    ]

    static func normalizeWord(_ value: String) -> String {
        let lowered = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = lowered.unicodeScalars.map { scalar -> Character? in
            if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) || scalar == " " {
                return Character(scalar)
            }
            return nil
        }.compactMap { $0 }
        return String(filtered)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func titleKey(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    static func cleanTitle(_ title: String, prompt: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let fallback = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let chosen = trimmed.isEmpty ? fallback : trimmed
        return String(chosen.prefix(maxTitleLength))
    }

    static func titleIsAvailable(_ title: String, existing: [String], ignoring: String? = nil) -> Bool {
        let key = titleKey(title)
        guard !key.isEmpty, key.count <= maxTitleLength else { return false }
        if reservedTitles.contains(key) { return false }
        let ignored = ignoring.map(CustomWordRules.titleKey)
        return !existing.map(CustomWordRules.titleKey).contains { candidate in
            candidate == key && candidate != ignored
        }
    }

    static func pairKey(insiderCanonical: String, mismatchCanonical: String) -> String {
        [normalizeWord(insiderCanonical), normalizeWord(mismatchCanonical)].sorted().joined(separator: "|")
    }

    static func isShortForm(_ short: String, of full: String) -> Bool {
        let compact = normalizeWord(short).replacingOccurrences(of: " ", with: "")
        guard (2...5).contains(compact.count) else { return false }
        let words = significantWords(full)
        guard words.count >= 2 else { return false }
        let initials = words.compactMap(\.first).map(String.init).joined()
        return compact == initials
    }

    static func wordsCollide(_ left: [String], _ right: [String]) -> Bool {
        for a in left {
            for b in right {
                let normalA = normalizeWord(a)
                let normalB = normalizeWord(b)
                if !normalA.isEmpty && normalA == normalB { return true }
                if isShortForm(a, of: b) || isShortForm(b, of: a) { return true }
                if isLookalike(a, b) { return true }
            }
        }
        return false
    }

    /// True when two words are one or two letters apart, like Macaron and Macaroon.
    /// Numbered sequels such as Iron Man and Iron Man 2 stay allowed.
    static func isLookalike(_ left: String, _ right: String) -> Bool {
        if isNumberedSequel(left, right) { return false }
        let a = lettersOnly(left)
        let b = lettersOnly(right)
        if a.isEmpty || b.isEmpty || a == b { return false }
        let shorter = min(a.count, b.count)
        guard shorter >= 5 else { return false }
        let distance = editDistance(a, b)
        if distance == 1 { return true }
        if distance == 2, shorter >= 8, sharedCount(a, b, fromStart: true) >= 3 {
            return true
        }
        return false
    }

    static func acceptable(
        insiderWord: String,
        mismatchWord: String,
        insiderCanonical: String,
        mismatchCanonical: String,
        category: String,
        againstWords: [[String]],
        blockedPairKeys: Set<String>
    ) -> Bool {
        let insider = insiderWord.trimmingCharacters(in: .whitespacesAndNewlines)
        let mismatch = mismatchWord.trimmingCharacters(in: .whitespacesAndNewlines)
        let topic = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !insider.isEmpty, !mismatch.isEmpty, !topic.isEmpty else { return false }
        guard insider.count <= maxWordLength, mismatch.count <= maxWordLength, topic.count <= maxWordLength else { return false }
        let leftCanonical = normalizeWord(insiderCanonical.isEmpty ? insider : insiderCanonical)
        let rightCanonical = normalizeWord(mismatchCanonical.isEmpty ? mismatch : mismatchCanonical)
        guard !leftCanonical.isEmpty, !rightCanonical.isEmpty, leftCanonical != rightCanonical else { return false }
        if isShortForm(insider, of: mismatch) || isShortForm(mismatch, of: insider) { return false }
        if isLookalike(insider, mismatch) || isLookalike(leftCanonical, rightCanonical) { return false }
        let key = pairKey(insiderCanonical: leftCanonical, mismatchCanonical: rightCanonical)
        if blockedPairKeys.contains(key) { return false }
        let names = [insider, mismatch, leftCanonical, rightCanonical]
        return !againstWords.contains { wordsCollide(names, $0) }
    }

    private static func lettersOnly(_ value: String) -> String {
        String(normalizeWord(value).filter(\.isLetter))
    }

    private static func isNumberedSequel(_ left: String, _ right: String) -> Bool {
        let leftMarked = hasSequelMark(left)
        let rightMarked = hasSequelMark(right)
        guard leftMarked || rightMarked else { return false }
        let leftStem = leftMarked ? sequelStem(left) : lettersOnly(left)
        let rightStem = rightMarked ? sequelStem(right) : lettersOnly(right)
        return !leftStem.isEmpty && leftStem == rightStem
    }

    private static func hasSequelMark(_ value: String) -> Bool {
        value.lowercased().range(
            of: #"\b(\d+|ii|iii|iv|vi|vii|viii|ix|xi|xii)\b"#,
            options: .regularExpression
        ) != nil
    }

    private static func sequelStem(_ value: String) -> String {
        var letters = lettersOnly(value)
        for suffix in ["xii", "viii", "vii", "iii", "ii", "iv", "vi", "ix", "xi"]
        where letters.hasSuffix(suffix) && letters.count > suffix.count + 2 {
            letters.removeLast(suffix.count)
            break
        }
        return letters
    }

    private static func sharedCount(_ left: String, _ right: String, fromStart: Bool) -> Int {
        let a = Array(fromStart ? left : String(left.reversed()))
        let b = Array(fromStart ? right : String(right.reversed()))
        var count = 0
        for index in 0..<min(a.count, b.count) {
            if a[index] != b[index] { break }
            count += 1
        }
        return count
    }

    private static func editDistance(_ left: String, _ right: String) -> Int {
        let a = Array(left)
        let b = Array(right)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = Array(repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            previous = current
        }
        return previous[b.count]
    }

    private static func significantWords(_ value: String) -> [String] {
        let skip: Set<String> = ["a", "an", "the", "of", "and"]
        return normalizeWord(value)
            .split(separator: " ")
            .map(String.init)
            .filter { !skip.contains($0) }
    }
}

enum CustomPackID {
    static let prefix = "custom:"

    static func make(_ id: String) -> String {
        id.hasPrefix(prefix) ? id : prefix + id
    }

    static func raw(_ id: String) -> String {
        id.hasPrefix(prefix) ? String(id.dropFirst(prefix.count)) : id
    }

    static func isCustom(_ id: String) -> Bool {
        id.hasPrefix(prefix)
    }
}

struct DealCandidate: Equatable, Sendable {
    enum Source: Equatable, Sendable {
        case builtIn(id: String)
        case custom(id: String)
    }

    let source: Source
    let remaining: Int
}

enum PackSourceChooser {
    static func choose(_ candidates: [DealCandidate], index: (Int) -> Int) -> DealCandidate.Source? {
        let available = candidates.filter { $0.remaining > 0 }
        guard !available.isEmpty else { return nil }
        let chosen = min(max(0, index(available.count)), available.count - 1)
        return available[chosen].source
    }
}
