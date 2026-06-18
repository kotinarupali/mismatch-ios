import Foundation

@MainActor
@Observable
final class SessionSummaryViewModel {
    private let dependencies: AppDependencies

    var showPartyPersonas = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var gamesPlayedCount: Int {
        dependencies.gameSessionStore.gamesPlayedCount
    }

    var scoreboardRows: [SessionScoreRow] {
        dependencies.gameSessionStore.sessionSummaryScoreboard()
    }

    var finalScoreboardRows: [FinalScoreboardRow] {
        dependencies.gameSessionStore.sessionSummaryFinalScoreboardRows()
    }

    var showsDetailedScoreboard: Bool {
        !finalScoreboardRows.isEmpty
    }

    var showsLeaderboard: Bool {
        gamesPlayedCount > 0 || !scoreboardRows.isEmpty
    }

    var hasScores: Bool {
        scoreboardRows.contains { $0.sessionScore > 0 || $0.roundPoints > 0 }
    }

    var leaderHeadline: String? {
        guard let topScore = scoreboardRows.first?.sessionScore, topScore > 0 else { return nil }
        let leaders = scoreboardRows.filter { $0.sessionScore == topScore }.map(\.displayName)
        guard !leaders.isEmpty else { return nil }

        let names = leaders.formatted(.list(type: .and))
        let rankLabel = leaders.count > 1 ? "tied for 1st" : "in 1st"
        let pointsLabel = topScore == 1 ? "1 point" : "\(topScore) points"
        return "\(names) \(rankLabel) with \(pointsLabel)"
    }

    var subtitle: String {
        if gamesPlayedCount > 0 {
            let gameLabel = gamesPlayedCount == 1 ? "1 game" : "\(gamesPlayedCount) games"
            return "\(gameLabel) tonight · ranked by total points"
        }
        return "Ranked by total points this game night"
    }

    var sessionOutcome: RoundOutcome? {
        dependencies.gameSessionStore.sessionWinner
    }

    var showsGameOutcome: Bool {
        sessionOutcome != nil
    }

    var winnerHeadline: String? {
        guard let outcome = sessionOutcome else { return nil }
        let alliance = dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
        return outcome.celebrationHeadline(allianceEnabled: alliance)
    }

    var winningRolesOrdered: [Role] {
        guard let outcome = sessionOutcome else { return [] }
        let alliance = dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
        return Role.allCases.filter { outcome.winningRoles(allianceEnabled: alliance).contains($0) }
    }

    var winnerPlayerNames: [String] {
        let winnerIds = dependencies.gameSessionStore.sessionWinnerPlayerIds()
        return dependencies.gameSessionStore.finalPlayerReveals()
            .filter { winnerIds.contains($0.id) }
            .map(\.displayName)
    }

    var finalInsiderWord: String {
        dependencies.gameSessionStore.insiderWord ?? "Unknown"
    }

    var finalMismatchWord: String {
        dependencies.gameSessionStore.mismatchWord ?? "Unknown"
    }

    var personaCards: [PlayerPersonaCard] {
        dependencies.gameSessionStore.playerPersonaCards()
    }

    var mismatchGhostAllianceEnabled: Bool {
        dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
    }

    func onAppear() {
        applyProfileStatsIfNeeded()
        showPartyPersonas = true
    }

    func backToHomeTapped() {
        showPartyPersonas = false
        dependencies.newGameNight()
    }

    private func applyProfileStatsIfNeeded() {
        guard let session = dependencies.gameSessionStore.currentSession,
              !session.profileStatsApplied else { return }

        let winners = dependencies.gameSessionStore.sessionWinnerPlayerIds()
        do {
            try dependencies.profileRepository.applySessionStats(
                from: session,
                winnerPlayerIds: winners
            )
            dependencies.gameSessionStore.markProfileStatsApplied()
        } catch {
            // Profiles are optional — ignore write failures during summary.
        }
    }
}
