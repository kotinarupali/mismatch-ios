import Testing
@testable import mismatch

struct WordPackLoaderTests {

    @Test func loadsGeneralPackWith130Pairs() throws {
        let loader = WordPackLoader()
        let pack = try loader.loadBuiltIn(packId: "general")

        #expect(pack.id == "general")
        #expect(pack.isBuiltIn)
        #expect(pack.pairs.count == 130)
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

struct SessionWinCheckerTests {

    @Test func gameContinuesAfterSingleInsiderEliminated() {
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B"))
        ]
        let settings = GameSettings.default
        #expect(SessionWinChecker.checkWinner(players: players, settings: settings) == nil)
    }

    @Test func insidersWinWhenAllMismatchEliminated() {
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: .default) == .insiderSideWins)
    }

    @Test func mismatchWinsWhenAllInsidersEliminated() {
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: .default) == .mismatchWins)
    }

    @Test func allianceOutsidersWinWhenInsidersEliminated() {
        var settings = GameSettings.default
        settings.mismatchGhostAlliance = true
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B")),
            PlayerSlot(displayName: "D", avatarColor: .orange, assignment: RoleAssignment(role: .ghost), isEliminated: true)
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: settings) == .outsiderSideWins)
    }

    @Test func allianceInsidersWinWhenAllOutsidersEliminated() {
        var settings = GameSettings.default
        settings.mismatchGhostAlliance = true
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .ghost), isEliminated: true),
            PlayerSlot(displayName: "D", avatarColor: .orange, assignment: RoleAssignment(role: .insider, word: "A"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: settings) == .insiderSideWins)
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

struct CardPickRulesTests {

    @Test func scalesWithPlayerCount() {
        #expect(CardPickRules.faceDownCardCount(playerCount: 3) == 3)
        #expect(CardPickRules.faceDownCardCount(playerCount: 5) == 5)
        #expect(CardPickRules.faceDownCardCount(playerCount: 8) == 6)
    }
}

struct GameSettingsTests {

    @Test func discussionTimerOffByDefault() {
        #expect(GameSettings.default.discussionTimerEnabled == false)
    }
}

struct PassThePhoneOrderTests {

    @Test @MainActor func distributeRolesSetsRandomPassOrder() throws {
        let store = GameSessionStore()
        store.createSession()
        let players = (1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        }
        store.setPlayers(players)

        let pair = WordPair(id: "1", insiderWord: "A", mismatchWord: "B", category: "Test")
        try store.distributeRoles(wordPair: pair)

        let order = store.passThePhoneOrder()
        #expect(order.count == 5)
        #expect(Set(order.map(\.id)) == Set(players.map(\.id)))
        #expect(store.currentSession?.passOrderPlayerIds.count == 5)
    }

    @Test @MainActor func claimedCardsTracksPickedSlots() throws {
        let store = GameSessionStore()
        store.createSession()
        let alice = PlayerSlot(displayName: "Alice", avatarColor: .red)
        let bob = PlayerSlot(displayName: "Bob", avatarColor: .blue)
        store.setPlayers([alice, bob, PlayerSlot(displayName: "C", avatarColor: .green)])

        store.markCardOpened(playerId: alice.id, cardIndex: 2)

        let claimed = store.claimedCards()
        #expect(claimed.count == 1)
        #expect(claimed[0].index == 2)
        #expect(claimed[0].playerName == "Alice")
    }
}
