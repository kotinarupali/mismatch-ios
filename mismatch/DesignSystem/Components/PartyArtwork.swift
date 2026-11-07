import SwiftUI

enum PartyArt {
    static let appIcon = "ArtAppIcon"
    /// In-app mark. Same size on the home screen and in How to Play.
    static let appIconDisplaySize: CGFloat = 72
    static let insider = "ArtRoleInsider"
    static let mismatch = "ArtRoleMismatch"
    static let ghost = "ArtRoleGhost"
    static let howToPlay = "IconHowToPlay"
    static let settings = "IconSettings"
    static let customPacks = "IconCustomPacks"
    static let dealCards = "IconDealCards"
    static let profiles = "IconProfiles"
    static let host = "IconHost"
    static let wordPacks = "IconWordPacks"
    static let rules = "IconRules"
    static let discuss = "IconDiscuss"
    static let vote = "IconVote"
    static let trophy = "IconTrophy"

    static func name(for role: Role) -> String {
        switch role {
        case .insider: insider
        case .mismatch: mismatch
        case .ghost: ghost
        }
    }
}

/// Glossy sticker from the party art set.
struct PartySticker: View {
    let name: String
    var size: CGFloat = 44
    var accessibilityLabel: String? = nil

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: size * 0.08, y: size * 0.04)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityHidden(accessibilityLabel == nil)
    }
}
