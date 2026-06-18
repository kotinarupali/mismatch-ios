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
}

struct WordPairUsageStoreTests {

    @Test func tracksUsedPairsAndRemainingCount() {
        let defaults = UserDefaults(suiteName: "WordPairUsageStoreTests")!
        defaults.removePersistentDomain(forName: "WordPairUsageStoreTests")
        let store = WordPairUsageStore(defaults: defaults)

        #expect(store.stats(totalPairs: 5, packId: "general").remaining == 5)

        store.markUsed("pair-1", packId: "general")
        store.markUsed("pair-2", packId: "general")

        let stats = store.stats(totalPairs: 5, packId: "general")
        #expect(stats.used == 2)
        #expect(stats.remaining == 3)
    }

    @Test func resetClearsUsedPairs() {
        let defaults = UserDefaults(suiteName: "WordPairUsageStoreTestsReset")!
        defaults.removePersistentDomain(forName: "WordPairUsageStoreTestsReset")
        let store = WordPairUsageStore(defaults: defaults)

        store.markUsed("pair-1", packId: "general")
        store.reset(packId: "general")

        #expect(store.stats(totalPairs: 5, packId: "general").used == 0)
    }
}

struct WordPairSelectorTests {

    @Test func nextPairSkipsPreviouslyUsedPairs() throws {
        let defaults = UserDefaults(suiteName: "WordPairSelectorTests")!
        defaults.removePersistentDomain(forName: "WordPairSelectorTests")
        let loader = WordPackLoader()
        let usageStore = WordPairUsageStore(defaults: defaults)
        let selector = WordPairSelector(loader: loader, usageStore: usageStore)

        let first = try selector.nextPair()
        selector.markUsed(first)

        let second = try selector.nextPair()
        #expect(second.id != first.id)
    }

    @Test func nextPairResetsWhenAllPairsAreUsed() throws {
        let defaults = UserDefaults(suiteName: "WordPairSelectorTestsReset")!
        defaults.removePersistentDomain(forName: "WordPairSelectorTestsReset")
        let loader = WordPackLoader()
        let usageStore = WordPairUsageStore(defaults: defaults)
        let selector = WordPairSelector(loader: loader, usageStore: usageStore)
        let pack = try loader.loadBuiltIn()

        for pair in pack.pairs {
            usageStore.markUsed(pair.id, packId: "general")
        }

        let next = try selector.nextPair()
        #expect(pack.pairs.contains(where: { $0.id == next.id }))
        #expect(usageStore.stats(totalPairs: pack.pairs.count, packId: "general").used == 0)
    }
}

struct GameSessionMinimumPlayerTests {

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

    @Test func mismatchWinsWhenOutsidersTieInsiderCount() {
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: .default) == .mismatchWins)
    }

    @Test func mismatchWinsWhenOutsidersOutnumberInsiders() {
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "A2", avatarColor: .orange, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .mismatch, word: "B")),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: .default) == .mismatchWins)
    }

    @Test func gameContinuesWhileInsidersHoldMajority() {
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "D", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: .default) == nil)
    }

    @Test func allianceOutsidersWinWhenOutsidersTieInsiders() {
        var settings = GameSettings.default
        settings.mismatchGhostAlliance = true
        let players = [
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B"))
        ]
        #expect(SessionWinChecker.checkWinner(players: players, settings: settings) == .outsiderSideWins)
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

    @Test func allianceTeamWinsWhenMismatchWinsAlone() {
        var settings = GameSettings.default
        settings.mismatchGhostAlliance = true
        let outcome = RoundOutcome.mismatchWins
        #expect(outcome.winningRoles(allianceEnabled: true) == [.mismatch, .ghost])
        #expect(outcome.celebrationHeadline(allianceEnabled: true) == "Mismatch & Ghost win!")
    }

    @Test func allianceTeamWinsWhenGhostWinsAlone() {
        let outcome = RoundOutcome.ghostWins
        #expect(outcome.winningRoles(allianceEnabled: true) == [.mismatch, .ghost])
        #expect(outcome.celebrationHeadline(allianceEnabled: true) == "Mismatch & Ghost win!")
    }
}

struct RoleDistributionTableTests {

    @Test func fourPlayersGhostOff() {
        let counts = RoleDistributionTable.counts(playerCount: 4, ghostEnabled: false)
        #expect(counts.insider == 3)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 0)
    }

    @Test func fourPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 4, ghostEnabled: true)
        #expect(counts.insider == 3)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 0)
    }

    @Test func fivePlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 5, ghostEnabled: true)
        #expect(counts.insider == 3)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 1)
    }

    @Test func sevenPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 7, ghostEnabled: true)
        #expect(counts.insider == 4)
        #expect(counts.mismatch == 2)
        #expect(counts.ghost == 1)
    }

    @Test func ninePlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 9, ghostEnabled: true)
        #expect(counts.insider == 5)
        #expect(counts.mismatch == 3)
        #expect(counts.ghost == 1)
    }

    @Test func elevenPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 11, ghostEnabled: true)
        #expect(counts.insider == 6)
        #expect(counts.mismatch == 3)
        #expect(counts.ghost == 2)
    }

    @Test func threePlayersOneMismatch() {
        let counts = RoleDistributionTable.counts(playerCount: 3, ghostEnabled: false)
        #expect(counts.insider == 2)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 0)
    }

    @Test func sixPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 6, ghostEnabled: true)
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 1)
        #expect(counts.insider == 4)
    }

    @Test func eightPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 8, ghostEnabled: true)
        #expect(counts.mismatch == 2)
        #expect(counts.ghost == 1)
        #expect(counts.insider == 5)
    }

    @Test func tenPlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 10, ghostEnabled: true)
        #expect(counts.mismatch == 3)
        #expect(counts.ghost == 1)
        #expect(counts.insider == 6)
    }

    @Test func twelvePlayersGhostOn() {
        let counts = RoleDistributionTable.counts(playerCount: 12, ghostEnabled: true)
        #expect(counts.mismatch == 3)
        #expect(counts.ghost == 2)
        #expect(counts.insider == 7)
    }

    @Test func insidersAreAlwaysMajority() {
        for count in 3...16 {
            let counts = RoleDistributionTable.counts(playerCount: count, ghostEnabled: true)
            #expect(counts.total == count)
            #expect(counts.insider > counts.mismatch + counts.ghost)
        }
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
        #expect(roles.filter { $0 == .insider }.count == 5)
        #expect(roles.filter { $0 == .mismatch }.count == 2)
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

    @Test func cloudGuestVotingOffByDefault() {
        #expect(GameSettings.default.cloudGuestVotingEnabled == false)
    }
}

struct HostPreferencesTests {

    @Test func appliesTimerToGameSettings() {
        let preferences = HostPreferences(discussionTimerEnabled: true, timerMinutes: 5)
        let settings = preferences.applying(to: .default)

        #expect(settings.discussionTimerEnabled == true)
        #expect(settings.timerSeconds == 300)
    }

    @Test func normalizesInvalidTimerMinutes() {
        let preferences = HostPreferences(discussionTimerEnabled: true, timerMinutes: 7).normalized()
        #expect(preferences.timerMinutes == HostPreferences.default.timerMinutes)
    }

    @Test @MainActor func savedPreferencesApplyToNewSession() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let preferencesStore = HostPreferencesStore(defaults: defaults)
        preferencesStore.save(HostPreferences(discussionTimerEnabled: true, timerMinutes: 2))

        let sessionStore = GameSessionStore()
        sessionStore.createSession(settings: preferencesStore.load().applying(to: .default))

        #expect(sessionStore.currentSession?.settings.discussionTimerEnabled == true)
        #expect(sessionStore.currentSession?.settings.timerSeconds == 120)
    }
}

struct PassThePhoneOrderTests {

    @Test @MainActor func passThePhoneViewModelStartsBeforeAllCardsOpened() throws {
        let dependencies = AppDependencies()
        dependencies.gameSessionStore.createSession()
        let players = (1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        }
        dependencies.gameSessionStore.setPlayers(players)
        dependencies.gameSessionStore.setSeatingOrder(players.map(\.id))

        let pair = WordPair(id: "1", insiderWord: "A", mismatchWord: "B", category: "Test")
        try dependencies.gameSessionStore.distributeRoles(wordPair: pair)

        let viewModel = PassThePhoneViewModel(dependencies: dependencies)
        #expect(viewModel.title != "All roles revealed")
        #expect(viewModel.awaitingHandoff == true)
        #expect(viewModel.isMissingRoleAssignments == false)
        #expect(viewModel.canShowCardPick == false)
    }

    @Test @MainActor func distributeRolesRotatesSeatingOrder() throws {
        let store = GameSessionStore()
        store.createSession()
        let host = PlayerSlot(displayName: "Host", avatarColor: .blue, isHost: true)
        let players = [
            host,
            PlayerSlot(displayName: "P2", avatarColor: AvatarColor.forIndex(1)),
            PlayerSlot(displayName: "P3", avatarColor: AvatarColor.forIndex(2)),
            PlayerSlot(displayName: "P4", avatarColor: AvatarColor.forIndex(3)),
            PlayerSlot(displayName: "P5", avatarColor: AvatarColor.forIndex(4)),
        ]
        store.setPlayers(players)
        store.setSeatingOrder(players.map(\.id))

        let pair = WordPair(id: "1", insiderWord: "A", mismatchWord: "B", category: "Test")
        try store.distributeRoles(wordPair: pair)

        let order = store.passThePhoneOrder().map(\.id)
        let seating = players.map(\.id)

        #expect(order.count == 5)
        #expect(Set(order) == Set(seating))

        guard let start = seating.firstIndex(of: order[0]) else {
            Issue.record("Pass order must start from a player in the seating sequence.")
            return
        }
        let rotated = Array(seating[start...] + seating[..<start])
        #expect(order == rotated)
    }

    @Test @MainActor func startDiscussionPicksRandomActiveStarter() throws {
        let store = GameSessionStore()
        store.createSession()
        store.setPlayers([
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .mismatch, word: "B")),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A")),
        ])
        store.setSeatingOrder(store.currentSession!.players.map(\.id))

        store.startDiscussion()

        let starterId = store.currentSession?.discussionStartPlayerId
        #expect(starterId != nil)
        #expect(store.discussionStarter != nil)
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

    @Test @MainActor func remainingOutsiderCountsExcludeEliminatedPlayers() throws {
        let store = GameSessionStore()
        store.createSession()
        store.setPlayers([
            PlayerSlot(displayName: "A", avatarColor: .red, assignment: RoleAssignment(role: .mismatch, word: "B")),
            PlayerSlot(displayName: "B", avatarColor: .blue, assignment: RoleAssignment(role: .ghost)),
            PlayerSlot(displayName: "C", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "D", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true),
        ])

        let counts = store.remainingOutsiderCounts()
        #expect(counts.mismatch == 1)
        #expect(counts.ghost == 1)
    }
}

struct LobbyViewModelTests {

    @Test @MainActor func autoEnablesGhostForTenPlayers() {
        let dependencies = AppDependencies()
        dependencies.gameSessionStore.createSession()
        let viewModel = LobbyViewModel(dependencies: dependencies)

        for index in 1...9 {
            viewModel.addNewPlayer(named: "P\(index)")
        }

        #expect(viewModel.totalPlayerCount == 10)
        #expect(viewModel.ghostEnabled == true)
        #expect(viewModel.projectedGhostCount == 1)
    }

    @Test @MainActor func keepsGhostOffWhenUserDisablesIt() {
        let dependencies = AppDependencies()
        dependencies.gameSessionStore.createSession()
        let viewModel = LobbyViewModel(dependencies: dependencies)

        for index in 1...9 {
            viewModel.addNewPlayer(named: "P\(index)")
        }

        viewModel.setGhostEnabled(false)
        viewModel.refreshSession()

        #expect(viewModel.ghostEnabled == false)
        #expect(viewModel.projectedGhostCount == 0)
    }

    @Test @MainActor func updatePlayerPersistsRenamedGuest() {
        let dependencies = AppDependencies()
        dependencies.gameSessionStore.createSession()
        let viewModel = LobbyViewModel(dependencies: dependencies)

        viewModel.addNewPlayer(named: "Alice")
        guard let guestId = viewModel.seatedPlayers.first(where: { !$0.isHost })?.id else {
            Issue.record("Expected a guest player.")
            return
        }

        viewModel.updatePlayer(id: guestId, name: "Alicia")

        #expect(viewModel.seatedPlayers.first(where: { $0.id == guestId })?.displayName == "Alicia")
        #expect(
            dependencies.gameSessionStore.currentSession?.players.first(where: { $0.id == guestId })?.displayName
                == "Alicia"
        )
    }
}

struct WordGuessMatcherTests {

    @Test func matchesIgnoringCaseAndWhitespace() {
        #expect(WordGuessMatcher.matches("  Apple ", secret: "apple"))
        #expect(WordGuessMatcher.matches("PARIS", secret: "paris"))
        #expect(WordGuessMatcher.matches("New  York", secret: "new york"))
        #expect(WordGuessMatcher.matches("wrong", secret: "apple") == false)
    }
}

struct GhostGuessTests {

    @Test @MainActor func eliminatingGhostPromptsGuessBeforeGameEnds() throws {
        let store = GameSessionStore()
        var settings = GameSettings.default
        settings.ghostEnabled = true
        store.createSession(settings: settings)
        store.setPlayers((1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        guard let ghostId = store.currentSession?.players.first(where: { $0.assignment?.role == .ghost })?.id else {
            Issue.record("Expected ghost player.")
            return
        }

        store.eliminate(playerId: ghostId)

        #expect(store.isGhostGuessPending == true)
        #expect(store.isSessionComplete == false)
    }

    @Test @MainActor func allianceGhostGuessWinCountsAsTeamWin() throws {
        let store = GameSessionStore()
        var settings = GameSettings.default
        settings.ghostEnabled = true
        settings.mismatchGhostAlliance = true
        store.createSession(settings: settings)
        store.setPlayers((1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        guard let ghostId = store.currentSession?.players.first(where: { $0.assignment?.role == .ghost })?.id else {
            Issue.record("Expected ghost player.")
            return
        }

        store.eliminate(playerId: ghostId)
        let isCorrect = store.submitGhostGuess("apple")

        #expect(isCorrect == true)
        #expect(store.sessionWinner == .outsiderSideWins)
        #expect(store.sessionWinner?.winningRoles(allianceEnabled: true) == [.mismatch, .ghost])
    }

    @Test @MainActor func correctGhostGuessEndsGameImmediately() throws {
        let store = GameSessionStore()
        var settings = GameSettings.default
        settings.ghostEnabled = true
        store.createSession(settings: settings)
        store.setPlayers((1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        guard let ghostId = store.currentSession?.players.first(where: { $0.assignment?.role == .ghost })?.id else {
            Issue.record("Expected ghost player.")
            return
        }

        store.eliminate(playerId: ghostId)
        let isCorrect = store.submitGhostGuess("apple")

        #expect(isCorrect == true)
        #expect(store.isGhostGuessPending == false)
        #expect(store.sessionWinner == .ghostWins)
        #expect(store.isSessionComplete == true)
    }

    @Test @MainActor func wrongGhostGuessResumesNormalWinCheck() throws {
        let store = GameSessionStore()
        var settings = GameSettings.default
        settings.ghostEnabled = true
        store.createSession(settings: settings)
        store.setPlayers((1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        guard let mismatchId = store.currentSession?.players.first(where: { $0.assignment?.role == .mismatch })?.id else {
            Issue.record("Expected mismatch player.")
            return
        }
        store.eliminate(playerId: mismatchId)
        store.continueAfterElimination()

        guard let ghostId = store.currentSession?.players.first(where: { $0.assignment?.role == .ghost })?.id else {
            Issue.record("Expected ghost player.")
            return
        }

        store.eliminate(playerId: ghostId)
        let isCorrect = store.submitGhostGuess("Banana")

        #expect(isCorrect == false)
        #expect(store.sessionWinner == .insiderSideWins)
        #expect(store.isSessionComplete == true)
    }
}

struct CloudCardDistributionTests {

    @Test func lobbyOptionsHideCloudWhenNotConfigured() {
        #expect(!DistributionMode.lobbyOptions.contains(.cloudQR))
    }

    @Test func applyRemoteCardSnapshotMarksPlayersPicked() {
        let store = GameSessionStore()
        store.createSession()
        let guestId = UUID()
        store.setPlayers([
            PlayerSlot(id: UUID(), displayName: "You", avatarColor: .blue, isHost: true),
            PlayerSlot(id: guestId, displayName: "Alex", avatarColor: .green, isHost: false),
            PlayerSlot(id: UUID(), displayName: "Sam", avatarColor: .orange, isHost: false)
        ])

        let snapshot = RemoteCardSessionSnapshot(
            players: [
                .init(id: guestId, displayName: "Alex", hasOpenedCard: true)
            ],
            claimedCards: [
                .init(cardIndex: 2, playerId: guestId, playerName: "Alex")
            ],
            faceDownCardCount: 4,
            showRoleOnCard: false,
            revision: 1
        )

        store.applyRemoteCardSnapshot(snapshot)

        let guest = store.currentSession?.players.first { $0.id == guestId }
        #expect(guest?.hasOpenedCard == true)
        #expect(guest?.pickedCardIndex == 2)
    }

    @Test func voteTalliesDecodeByPlayerId() {
        let guestId = UUID()
        let snapshot = RemoteCardSessionSnapshot(
            players: [],
            claimedCards: [],
            faceDownCardCount: 4,
            showRoleOnCard: false,
            revision: 2,
            votingEnabled: true,
            votingOpen: true,
            votingRound: 1,
            voteTallies: [guestId.uuidString: 3]
        )

        #expect(snapshot.voteTalliesByPlayerId[guestId] == 3)
    }
}

struct GuestVoteTieDetectorTests {
    @Test func detectsTieAmongTopVoteGetters() {
        let alice = UUID()
        let bob = UUID()
        let charlie = UUID()
        let active: Set<UUID> = [alice, bob, charlie]

        let tie = GuestVoteTieDetector.detect(
            tallies: [alice: 3, bob: 3, charlie: 1],
            activePlayerIds: active
        )

        #expect(tie?.voteCount == 3)
        #expect(Set(tie?.tiedPlayerIds ?? []) == [alice, bob])
    }

    @Test func ignoresEliminatedPlayersAndZeroVotes() {
        let alice = UUID()
        let bob = UUID()
        let eliminated = UUID()
        let active: Set<UUID> = [alice, bob]

        let tie = GuestVoteTieDetector.detect(
            tallies: [alice: 2, bob: 1, eliminated: 2],
            activePlayerIds: active
        )

        #expect(tie == nil)
    }

    @Test func returnsNilWhenOnlyOnePlayerLeads() {
        let alice = UUID()
        let bob = UUID()
        let active: Set<UUID> = [alice, bob]

        let tie = GuestVoteTieDetector.detect(
            tallies: [alice: 4, bob: 2],
            activePlayerIds: active
        )

        #expect(tie == nil)
    }
}

struct SessionScoreboardRankerTests {
    @Test func assignsSharedCompetitionRanks() {
        let rows = [
            SessionScoreRow(id: UUID(), displayName: "A", avatarColor: .blue, sessionScore: 8, roundPoints: 0, isHost: false, rank: 0),
            SessionScoreRow(id: UUID(), displayName: "B", avatarColor: .green, sessionScore: 8, roundPoints: 0, isHost: false, rank: 0),
            SessionScoreRow(id: UUID(), displayName: "C", avatarColor: .orange, sessionScore: 3, roundPoints: 0, isHost: false, rank: 0)
        ]

        let ranked = SessionScoreboardRanker.assignSharedRanks(to: rows)

        #expect(ranked.map(\.rank) == [1, 1, 3])
    }
}

struct ScoringEngineTests {

    @Test func survivorEarnsOnePointPerRound() {
        let insider = PlayerSlot(displayName: "A", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A"))
        let eliminated = PlayerSlot(displayName: "B", avatarColor: .red, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true)

        let events = ScoringEngine.computeRoundScores(
            players: [insider, eliminated],
            eliminatedPlayerId: eliminated.id,
            ghostGuessCorrect: nil
        )

        #expect(ScoringEngine.totalPoints(for: events.filter { $0.playerId == insider.id }) == 1)
        #expect(events.contains { $0.playerId == eliminated.id } == false)
    }

    @Test func mismatchSurvivorEarnsOnlyOnePointPerRound() {
        let mismatch = PlayerSlot(displayName: "M", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B"))
        let eliminated = PlayerSlot(displayName: "I", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true)

        let events = ScoringEngine.computeRoundScores(
            players: [mismatch, eliminated],
            eliminatedPlayerId: eliminated.id,
            ghostGuessCorrect: nil
        )

        #expect(ScoringEngine.totalPoints(for: events.filter { $0.playerId == mismatch.id }) == 1)
    }

    @Test func survivingInsidersGetWinBonus() {
        let insider = PlayerSlot(displayName: "I", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A"))
        let mismatch = PlayerSlot(displayName: "M", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true)

        let events = ScoringEngine.computeSessionWinBonuses(
            players: [insider, mismatch],
            outcome: .insiderSideWins,
            settings: .default
        )

        #expect(ScoringEngine.totalPoints(for: events.filter { $0.playerId == insider.id }) == 3)
        #expect(events.contains { $0.playerId == mismatch.id } == false)
    }

    @Test func survivingMismatchGetsWinBonus() {
        let mismatch = PlayerSlot(displayName: "M", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B"))
        let insider = PlayerSlot(displayName: "I", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true)

        let events = ScoringEngine.computeSessionWinBonuses(
            players: [mismatch, insider],
            outcome: .mismatchWins,
            settings: .default
        )

        #expect(ScoringEngine.totalPoints(for: events.filter { $0.playerId == mismatch.id }) == 3)
    }

    @Test func eliminatedGhostWithCorrectGuessEarnsSixPoints() {
        let insider = PlayerSlot(displayName: "I", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A"))
        let ghost = PlayerSlot(displayName: "G", avatarColor: .purple, assignment: RoleAssignment(role: .ghost, word: nil), isEliminated: true)

        let events = ScoringEngine.computeRoundScores(
            players: [insider, ghost],
            eliminatedPlayerId: ghost.id,
            ghostGuessCorrect: true
        )

        #expect(ScoringEngine.totalPoints(for: events.filter { $0.playerId == ghost.id }) == 6)
        #expect(ScoringEngine.totalPoints(for: events.filter { $0.playerId == insider.id }) == 1)
    }

    @Test func eliminatedInsiderDoesNotCountAsSessionWinner() {
        let store = GameSessionStore()
        store.createSession()
        store.setPlayers([
            PlayerSlot(displayName: "I1", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A")),
            PlayerSlot(displayName: "I2", avatarColor: .blue, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true),
            PlayerSlot(displayName: "M", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true)
        ])

        #expect(store.sessionWinnerPlayerIds().contains(store.currentSession!.players[0].id))
        #expect(store.sessionWinnerPlayerIds().contains(store.currentSession!.players[1].id) == false)
    }

    @Test func eliminatedMismatchDoesNotCountAsSessionWinner() {
        let store = GameSessionStore()
        store.createSession()
        store.setPlayers([
            PlayerSlot(displayName: "M1", avatarColor: .orange, assignment: RoleAssignment(role: .mismatch, word: "B")),
            PlayerSlot(displayName: "M2", avatarColor: .red, assignment: RoleAssignment(role: .mismatch, word: "B"), isEliminated: true),
            PlayerSlot(displayName: "I", avatarColor: .green, assignment: RoleAssignment(role: .insider, word: "A"), isEliminated: true)
        ])

        #expect(store.sessionWinnerPlayerIds().contains(store.currentSession!.players[0].id))
        #expect(store.sessionWinnerPlayerIds().contains(store.currentSession!.players[1].id) == false)
    }

    @Test @MainActor func gameSessionStoreAppliesWinBonusWhenInsidersWin() throws {
        let store = GameSessionStore()
        store.createSession()
        store.setPlayers((1...5).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        guard let mismatchId = store.currentSession?.players.first(where: { $0.assignment?.role == .mismatch })?.id else {
            Issue.record("Expected mismatch player.")
            return
        }

        store.eliminate(playerId: mismatchId)

        #expect(store.isSessionComplete == true)
        #expect(store.sessionEndScoreEvents.isEmpty == false)

        let insiderScores = store.currentSession?.players
            .filter { $0.assignment?.role == .insider && !$0.isEliminated }
            .map(\.sessionScore) ?? []
        #expect(insiderScores.allSatisfy { $0 >= 4 })
    }

    @Test @MainActor func finalScoreboardGainsMatchSessionTotalsAcrossRounds() throws {
        let dependencies = AppDependencies()
        let store = dependencies.gameSessionStore
        var settings = GameSettings.default
        settings.ghostEnabled = false
        store.createSession(settings: settings)
        store.setPlayers([
            PlayerSlot(displayName: "Adrian", avatarColor: .orange),
            PlayerSlot(displayName: "Carol", avatarColor: .green),
            PlayerSlot(displayName: "You", avatarColor: .blue, isHost: true),
            PlayerSlot(displayName: "Ben", avatarColor: .yellow)
        ])

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        let insiderIds = store.currentSession!.players
            .filter { $0.assignment?.role == .insider }
            .map(\.id)
        guard insiderIds.count >= 2 else {
            Issue.record("Expected at least two insiders.")
            return
        }

        store.eliminate(playerId: insiderIds[0])
        store.continueAfterElimination()
        store.eliminate(playerId: insiderIds[1])

        let viewModel = ResultsViewModel(dependencies: dependencies)

        #expect(store.roundsPlayed == 2)
        #expect(store.gamesPlayedCount == 1)
        #expect(store.sessionWinner == .mismatchWins)
        for row in viewModel.finalScoreboardRows {
            #expect(row.pointsGained == row.sessionScore)
        }
    }

    @Test @MainActor func sessionSummaryFinalScoreboardIncludesRolesAndEliminations() throws {
        let dependencies = AppDependencies()
        let store = dependencies.gameSessionStore
        var settings = GameSettings.default
        settings.ghostEnabled = false
        store.createSession(settings: settings)
        store.setPlayers([
            PlayerSlot(displayName: "Adrian", avatarColor: .orange),
            PlayerSlot(displayName: "Carol", avatarColor: .green),
            PlayerSlot(displayName: "You", avatarColor: .blue, isHost: true),
            PlayerSlot(displayName: "Ben", avatarColor: .yellow)
        ])

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        let mismatchId = store.currentSession!.players
            .first(where: { $0.assignment?.role == .mismatch })?.id
        guard let mismatchId else {
            Issue.record("Expected mismatch player.")
            return
        }

        store.eliminate(playerId: mismatchId)
        store.markSessionEnded()

        let rows = store.sessionSummaryFinalScoreboardRows()
        #expect(rows.count == 4)

        let mismatchRow = rows.first { $0.id == mismatchId }
        #expect(mismatchRow?.role == .mismatch)
        #expect(mismatchRow?.isEliminated == true)

        let insiderRows = rows.filter { $0.role == .insider }
        #expect(insiderRows.contains { $0.isWinner })
    }

    @Test @MainActor func gamesPlayedCountIncrementsOnCompletionAndPersistsAcrossPlayAgain() throws {
        let dependencies = AppDependencies()
        let store = dependencies.gameSessionStore
        var settings = GameSettings.default
        settings.ghostEnabled = false
        store.createSession(settings: settings)
        store.setPlayers((1...4).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        let insiderIds = store.currentSession!.players
            .filter { $0.assignment?.role == .insider }
            .map(\.id)
        guard insiderIds.count >= 2 else {
            Issue.record("Expected at least two insiders.")
            return
        }

        #expect(store.gamesPlayedCount == 0)

        store.eliminate(playerId: insiderIds[0])
        store.continueAfterElimination()
        store.eliminate(playerId: insiderIds[1])

        #expect(store.isSessionComplete == true)
        #expect(store.gamesPlayedCount == 1)

        store.resetRoundForPlayAgain()

        #expect(store.gamesPlayedCount == 1)
        #expect(store.roundsPlayed == 0)
    }

    @Test @MainActor func sessionScoresPersistAcrossPlayAgain() throws {
        let dependencies = AppDependencies()
        let store = dependencies.gameSessionStore
        var settings = GameSettings.default
        settings.ghostEnabled = false
        store.createSession(settings: settings)
        store.setPlayers((1...4).map { index in
            PlayerSlot(displayName: "P\(index)", avatarColor: AvatarColor.forIndex(index))
        })

        let pair = WordPair(id: "1", insiderWord: "Apple", mismatchWord: "Apricot", category: "Fruit")
        try store.distributeRoles(wordPair: pair)

        let insiderIds = store.currentSession!.players
            .filter { $0.assignment?.role == .insider }
            .map(\.id)
        guard insiderIds.count >= 2 else {
            Issue.record("Expected at least two insiders.")
            return
        }

        store.eliminate(playerId: insiderIds[0])
        store.continueAfterElimination()
        store.eliminate(playerId: insiderIds[1])

        let scoresAfterGameOne = store.currentSession!.players.map(\.sessionScore)
        #expect(scoresAfterGameOne.contains { $0 > 0 })

        store.resetRoundForPlayAgain()

        #expect(store.currentSession!.players.map(\.sessionScore) == scoresAfterGameOne)

        store.markSessionEnded()
        let summaryRows = store.sessionSummaryScoreboard()
        #expect(summaryRows.contains { $0.sessionScore > 0 })
    }

    @Test func personaEngineAssignsPartyLegendToTopScorer() {
        let alex = UUID()
        let jordan = UUID()
        var session = GameSession()
        session.players = [
            PlayerSlot(id: alex, displayName: "Alex", avatarColor: .green, sessionScore: 8),
            PlayerSlot(id: jordan, displayName: "Jordan", avatarColor: .orange, sessionScore: 2)
        ]
        session.rounds = [
            Round(index: 0, scoreEvents: [
                ScoreEvent(playerId: alex, reason: .survived),
                ScoreEvent(playerId: jordan, reason: .survived)
            ])
        ]

        let cards = PersonaEngine.buildCards(from: session)
        let alexCard = cards.first { $0.id == alex }

        #expect(alexCard?.title == "Party Legend")
    }

    @Test func personaEngineAssignsGraveRobberForGhostGuess() {
        let ghost = UUID()
        var session = GameSession()
        session.players = [
            PlayerSlot(id: ghost, displayName: "Ghost", avatarColor: .purple, isEliminated: true, sessionScore: 6)
        ]
        session.rounds = [
            Round(
                index: 0,
                eliminatedPlayerId: ghost,
                scoreEvents: [ScoreEvent(playerId: ghost, reason: .ghostCorrectGuess)]
            )
        ]

        let cards = PersonaEngine.buildCards(from: session)

        #expect(cards.first?.title == "Grave Robber")
    }
}

struct ProfileRepositoryTests {
    @Test func createFetchAndDeleteProfile() throws {
        let dependencies = try AppDependencies.makeForTesting()
        let repository = dependencies.profileRepository

        let created = try repository.create(name: "Alex", avatarColor: .orange)
        #expect(created.name == "Alex")
        #expect(created.stats.totalPoints == 0)

        let fetched = try repository.fetch(id: created.id)
        #expect(fetched?.name == "Alex")

        let all = try repository.fetchAll()
        #expect(all.count == 1)

        try repository.delete(id: created.id)
        #expect(try repository.fetch(id: created.id) == nil)
    }

    @Test func findOrCreateReturnsExistingProfileForExactNameMatch() throws {
        let dependencies = try AppDependencies.makeForTesting()
        let repository = dependencies.profileRepository

        let created = try repository.create(name: "Alex", avatarColor: .orange)
        let resolved = try repository.findOrCreate(name: "Alex", avatarColor: .blue)

        #expect(resolved.id == created.id)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func findOrCreateTreatsDifferentCasingAsSeparateProfiles() throws {
        let dependencies = try AppDependencies.makeForTesting()
        let repository = dependencies.profileRepository

        _ = try repository.create(name: "Alex", avatarColor: .orange)
        let resolved = try repository.findOrCreate(name: "alex", avatarColor: .blue)

        #expect(resolved.name == "alex")
        #expect(try repository.fetchAll().count == 2)
    }

    @Test @MainActor func profileSuggestionsRequireThreeCharacters() throws {
        let dependencies = try AppDependencies.makeForTesting()
        let repository = dependencies.profileRepository
        _ = try repository.create(name: "Freya", avatarColor: .green)
        _ = try repository.create(name: "Adrian", avatarColor: .orange)

        dependencies.gameSessionStore.createSession()
        let viewModel = LobbyViewModel(dependencies: dependencies)

        viewModel.newPlayerName = "Fr"
        #expect(viewModel.profileSuggestions.isEmpty)

        viewModel.newPlayerName = "Fre"
        #expect(viewModel.profileSuggestions.map(\.name) == ["Freya"])
    }

    @Test @MainActor func addingLobbyPlayerCreatesProfileAutomatically() throws {
        let dependencies = AppDependencies()
        let viewModel = LobbyViewModel(dependencies: dependencies)

        viewModel.addNewPlayer(named: "Freya")

        #expect(viewModel.seatedPlayers.count == 1)
        #expect(viewModel.seatedPlayers[0].profileId != nil)

        let profiles = try dependencies.profileRepository.fetchAll()
        #expect(profiles.count == 1)
        #expect(profiles[0].name == "Freya")
    }

    @Test func applySessionStatsUpdatesLinkedProfile() throws {
        let dependencies = try AppDependencies.makeForTesting()
        let repository = dependencies.profileRepository
        let profile = try repository.create(name: "Jordan", avatarColor: .green)

        let insiderId = UUID()
        var session = GameSession(gamesPlayedCount: 1, profileStatsApplied: false)
        session.players = [
            PlayerSlot(
                id: insiderId,
                displayName: "Jordan",
                avatarColor: .green,
                assignment: RoleAssignment(role: .insider, word: "A"),
                sessionScore: 4,
                profileId: profile.id
            )
        ]
        session.sessionEndScoreEvents = [
            ScoreEvent(playerId: insiderId, reason: .insiderWinBonus)
        ]

        try repository.applySessionStats(from: session, winnerPlayerIds: [insiderId])

        let updated = try repository.fetch(id: profile.id)
        #expect(updated?.stats.totalPoints == 4)
        #expect(updated?.stats.gamesPlayed == 1)
        #expect(updated?.stats.winsAsInsider == 1)
        #expect(updated?.stats.currentStreak == 1)
    }
}
