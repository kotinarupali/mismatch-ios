import Testing
@testable import mismatch

struct WordPackLoaderTests {

    @Test func loadsGeneralPackWith30Pairs() throws {
        let loader = WordPackLoader()
        let pack = try loader.loadBuiltIn(packId: "general")

        #expect(pack.id == "general")
        #expect(pack.isBuiltIn)
        #expect(pack.pairs.count == 30)
    }

    @Test func gameSessionRequiresMinimumThreePlayers() {
        let session = GameSession(players: [
            PlayerSlot(displayName: "A", avatarColor: .red),
            PlayerSlot(displayName: "B", avatarColor: .blue)
        ])

        #expect(session.canStartGame == false)

        var readySession = session
        readySession.players.append(PlayerSlot(displayName: "C", avatarColor: .green))
        #expect(readySession.canStartGame == true)
    }
}

struct GameSessionStoreTests {

    @Test @MainActor func createAndResetSession() {
        let store = GameSessionStore()

        #expect(store.hasActiveSession == false)

        store.createSession()
        #expect(store.hasActiveSession == true)
        #expect(store.currentSession?.state == .lobby)

        store.reset()
        #expect(store.hasActiveSession == false)
        #expect(store.currentSession == nil)
    }
}

struct WinConditionEvaluatorTests {

    @Test func insiderSideWinsWhenMismatchEliminated() {
        let player = PlayerSlot(
            displayName: "Sam",
            avatarColor: .red,
            assignment: RoleAssignment(role: .mismatch, word: "Calzone")
        )
        #expect(WinConditionEvaluator.evaluate(eliminatedPlayer: player) == .insiderSideWins)
    }

    @Test func mismatchWinsWhenInsiderEliminated() {
        let player = PlayerSlot(
            displayName: "Sam",
            avatarColor: .red,
            assignment: RoleAssignment(role: .insider, word: "Pizza")
        )
        #expect(WinConditionEvaluator.evaluate(eliminatedPlayer: player) == .mismatchWins)
    }
}

struct RoleDistributionTableTests {

    @Test func fourPlayersGhostOff() {
        let counts = RoleDistributionTable.counts(playerCount: 4, ghostEnabled: false)
        #expect(counts.insider == 3)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 0)
    }

    @Test func eightPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 8, ghostEnabled: true)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 1)
        #expect(counts.insider == 6)
    }

    @Test func distributionForMultiplePlayerCounts() {
        for count in [4, 6, 8, 10, 12, 16] {
            let counts = RoleDistributionTable.counts(playerCount: count, ghostEnabled: true)
            #expect(counts.total == count)
        }
    }
}

struct RoleAssignerTests {

    @Test func assignsRolesForEightPlayers() throws {
        let players = (1...8).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        }
        let pair = WordPair(id: "1", insiderWord: "A", mismatchWord: "B", category: "Test")
        var settings = GameSettings.default
        settings.ghostEnabled = true

        let assigned = try RoleAssigner().assign(players: players, wordPair: pair, settings: settings)

        #expect(assigned.count == 8)
        let roles = assigned.compactMap { $0.assignment?.role }
        #expect(roles.filter { $0 == .insider }.count == 6)
        #expect(roles.filter { $0 == .mismatch }.count == 1)
        #expect(roles.filter { $0 == .ghost }.count == 1)
    }
}

struct QRCodeGeneratorTests {

    @Test func generatesQRImage() {
        let image = QRCodeGenerator.image(from: "http://192.168.1.10:8080/c/abc123")
        #expect(image != nil)
    }
}

struct CardURLBuilderTests {

    @Test func buildsCardURL() {
        let url = CardURLBuilder().cardURL(baseURL: "http://192.168.1.10:8080", token: "abc")
        #expect(url == "http://192.168.1.10:8080/c/abc")
    }
}
