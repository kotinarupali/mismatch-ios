import Foundation

enum SessionScoreboardRanker {
    /// Competition ranking: tied scores share the same rank; the next rank skips (e.g. 1, 1, 3).
    static func assignSharedRanks(to sortedRows: [SessionScoreRow]) -> [SessionScoreRow] {
        guard !sortedRows.isEmpty else { return [] }

        var ranked: [SessionScoreRow] = []
        ranked.reserveCapacity(sortedRows.count)

        for (index, row) in sortedRows.enumerated() {
            let rank: Int
            if index == 0 {
                rank = 1
            } else if row.sessionScore == sortedRows[index - 1].sessionScore {
                rank = ranked[index - 1].rank
            } else {
                rank = index + 1
            }

            ranked.append(
                SessionScoreRow(
                    id: row.id,
                    displayName: row.displayName,
                    avatarColor: row.avatarColor,
                    sessionScore: row.sessionScore,
                    roundPoints: row.roundPoints,
                    isHost: row.isHost,
                    rank: rank
                )
            )
        }

        return ranked
    }
}
