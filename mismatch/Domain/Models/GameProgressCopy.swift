import Foundation

enum GameProgressCopy {
    static func gamesPlayedLabel(_ count: Int) -> String {
        count == 1 ? "1 game played" : "\(count) games played"
    }

    static func eliminationLabel(_ count: Int) -> String {
        count == 1 ? "1 elimination" : "\(count) eliminations"
    }

    static func scoreBannerTitle(gamesPlayed: Int, eliminationsInCurrentGame: Int) -> String {
        if eliminationsInCurrentGame > 0 {
            let gameNumber = gamesPlayed + 1
            return "Game \(gameNumber) · \(eliminationLabel(eliminationsInCurrentGame))"
        }
        if gamesPlayed > 0 {
            return gamesPlayedLabel(gamesPlayed) + " this session"
        }
        return "Game 1"
    }
}
