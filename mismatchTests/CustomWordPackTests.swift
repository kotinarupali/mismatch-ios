import Foundation
import Testing
@testable import mismatch

struct CustomWordRulesTests {
    @Test func newYorkAndItsInitialsCountAsTheSameWord() {
        #expect(CustomWordRules.isShortForm("NYC", of: "New York City"))
        #expect(CustomWordRules.wordsCollide(
            ["NYC", "nyc"],
            ["New York City", "new york city"]
        ))
    }

    @Test func lookalikeSpellingsAreRejected() {
        #expect(CustomWordRules.isLookalike("Macaron", "Macaroon"))
        #expect(CustomWordRules.isLookalike("Product Manager", "Project Manager"))
        #expect(!CustomWordRules.isLookalike("Macaron", "Brownie"))
        #expect(!CustomWordRules.isLookalike("Iron Man", "Iron Man 2"))
        #expect(!CustomWordRules.isLookalike("Creed II", "Creed III"))
        #expect(!CustomWordRules.isLookalike("Gladiator", "Gladiator II"))
        #expect(!CustomWordRules.acceptable(
            insiderWord: "Macaron",
            mismatchWord: "Macaroon",
            insiderCanonical: "macaron",
            mismatchCanonical: "macaroon",
            category: "Food",
            againstWords: [],
            blockedPairKeys: []
        ))
    }

    @Test func anotherPackMayReuseAWordButNotTheSamePair() {
        let blocked = Set([
            CustomWordRules.pairKey(insiderCanonical: "airport", mismatchCanonical: "train station")
        ])
        #expect(CustomWordRules.acceptable(
            insiderWord: "Airport",
            mismatchWord: "Bus Station",
            insiderCanonical: "airport",
            mismatchCanonical: "bus station",
            category: "Travel",
            againstWords: [],
            blockedPairKeys: blocked
        ))
        #expect(!CustomWordRules.acceptable(
            insiderWord: "Train Station",
            mismatchWord: "Airport",
            insiderCanonical: "train station",
            mismatchCanonical: "airport",
            category: "Travel",
            againstWords: [],
            blockedPairKeys: blocked
        ))
    }

    @Test func activeTitlesAreUniqueForTheHost() {
        #expect(!CustomWordRules.titleIsAvailable("Goa trip", existing: ["goa trip"]))
        #expect(CustomWordRules.titleIsAvailable("Goa trip", existing: ["goa trip"], ignoring: "Goa Trip"))
        #expect(!CustomWordRules.titleIsAvailable("General", existing: []))
    }

    @Test func eachSelectedPackHasAnEqualChance() {
        let candidates = [
            DealCandidate(source: .builtIn(id: "general"), remaining: 900),
            DealCandidate(source: .custom(id: "custom:pack"), remaining: 2),
        ]
        let choice = PackSourceChooser.choose(candidates) { _ in 1 }
        #expect(choice == .custom(id: "custom:pack"))
        let emptySkipped = PackSourceChooser.choose([
            DealCandidate(source: .builtIn(id: "general"), remaining: 4),
            DealCandidate(source: .custom(id: "custom:pack"), remaining: 0),
        ]) { _ in 0 }
        #expect(emptySkipped == .builtIn(id: "general"))
    }

    @Test func playedMarkStaysOnThePhoneUntilUpload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = CustomWordPackStore(defaults: defaults)
        var pack = CustomWordPack(id: "pack", prompt: "trip", title: "Goa", createdAt: nil, pairs: [
            CustomWordPair(
                id: "pair",
                insiderWord: "Beach",
                mismatchWord: "Pool",
                insiderCanonical: "beach",
                mismatchCanonical: "pool",
                category: "Places",
                playedAt: nil,
                isRemoved: false
            )
        ])
        store.save(CustomPackLibrary(packs: [pack], pendingPlayedPairIDs: []))
        pack.pairs[0].playedAt = "now"
        var library = store.load()
        library.packs = [pack]
        library.pendingPlayedPairIDs = ["pair"]
        store.save(library)
        let loaded = store.load()
        #expect(loaded.packs[0].pairs[0].playedAt == "now")
        #expect(loaded.pendingPlayedPairIDs == ["pair"])
    }
}
