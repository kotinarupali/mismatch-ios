import SwiftUI

struct GameNightPersonasList: View {
    let cards: [PlayerPersonaCard]
    var gamesPlayedCount: Int = 0
    var showsIntro: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            if showsIntro {
                header
            }

            if cards.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(cards) { card in
                        personaRow(card)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            MismatchLogoView(size: 64, style: .mini, showsShadow: false)

            Text("Tonight's cast")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.label)

            Text("Cute personas based on how everyone played.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)

            if gamesPlayedCount > 0 {
                Text(gamesPlayedCount == 1 ? "1 game this session" : "\(gamesPlayedCount) games this session")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.warning)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        Text("Not enough game history yet — but the vibes were immaculate.")
            .font(AppTypography.body)
            .foregroundStyle(AppColor.secondaryLabel)
            .multilineTextAlignment(.center)
            .padding(.vertical, 24)
    }

    private func personaRow(_ card: PlayerPersonaCard) -> some View {
        HStack(spacing: 14) {
            ZStack {
                AvatarView(name: card.displayName, color: card.avatarColor, size: 48)

                personaBadge(for: card)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 4, y: 4)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(card.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)

                Text(card.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor(for: card.accentHex))

                Text(card.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    accentColor(for: card.accentHex).opacity(0.16),
                    AppColor.backgroundElevated.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accentColor(for: card.accentHex).opacity(0.35), lineWidth: 1)
        }
    }

    private func personaBadge(for card: PlayerPersonaCard) -> some View {
        ZStack {
            Circle()
                .fill(accentColor(for: card.accentHex))
                .frame(width: 24, height: 24)
            Circle()
                .strokeBorder(.white.opacity(0.45), lineWidth: 1)
                .frame(width: 24, height: 24)
            Image(systemName: card.symbolName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: accentColor(for: card.accentHex).opacity(0.45), radius: 4, y: 2)
    }

    private func accentColor(for accent: PersonaAccent) -> Color {
        switch accent {
        case .gold: AppColor.warning
        case .coral: BrandPalette.mismatchMid
        case .mint: BrandPalette.insiderMid
        case .violet: BrandPalette.ghostMid
        case .sky: Color(red: 0.45, green: 0.72, blue: 1.0)
        case .rose: AppColor.accentSecondary
        case .amber: BrandPalette.sadMid
        }
    }
}

struct GameNightPersonasSheet: View {
    let cards: [PlayerPersonaCard]
    var gamesPlayedCount: Int = 0
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PartyRoomBackground(style: .reveal)

                ScrollView {
                    VStack(spacing: 20) {
                        GameNightPersonasList(
                            cards: cards,
                            gamesPlayedCount: gamesPlayedCount
                        )

                        PrimaryButton(title: "Back to Home") {
                            dismiss()
                            onDone()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Party Personas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    GameNightPersonasSheet(
        cards: [
            PlayerPersonaCard(
                id: UUID(),
                displayName: "Alex",
                avatarColor: .green,
                title: "Party Legend",
                subtitle: "Top score tonight with 8 points.",
                symbolName: "crown.fill",
                accentHex: .gold
            ),
            PlayerPersonaCard(
                id: UUID(),
                displayName: "Jordan",
                avatarColor: .purple,
                title: "Grave Robber",
                subtitle: "Snatched +6 with a perfect ghost guess.",
                symbolName: "wand.and.stars",
                accentHex: .violet
            )
        ],
        onDone: {}
    )
}
