import SwiftUI

extension View {
    func hostGameMenu(
        gameSessionStore: GameSessionStore? = nil,
        onRepick: @escaping () -> Void,
        onEndGame: @escaping () -> Void,
        onCheckPlayerRole: (() -> Void)? = nil
    ) -> some View {
        modifier(HostGameMenuModifier(
            gameSessionStore: gameSessionStore,
            onRepick: onRepick,
            onEndGame: onEndGame,
            onCheckPlayerRole: onCheckPlayerRole
        ))
    }
}

private struct HostGameMenuModifier: ViewModifier {
    @State private var showRepickConfirm = false
    @State private var showEndGameConfirm = false
    @State private var showScoresDashboard = false
    @State private var showPartyPersonas = false
    @State private var personaCards: [PlayerPersonaCard] = []

    let gameSessionStore: GameSessionStore?
    let onRepick: () -> Void
    let onEndGame: () -> Void
    let onCheckPlayerRole: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if gameSessionStore != nil {
                            Button {
                                showScoresDashboard = true
                            } label: {
                                Label("Scores", systemImage: "list.number")
                            }
                        }

                        if let onCheckPlayerRole {
                            Button {
                                onCheckPlayerRole()
                            } label: {
                                Label("Check Player Role", systemImage: "eye.fill")
                            }
                        }

                        Button {
                            showRepickConfirm = true
                        } label: {
                            Label("Re-pick Roles", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Button(role: .destructive) {
                            showEndGameConfirm = true
                        } label: {
                            Label("End Game", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppColor.label)
                    }
                }
            }
            .sheet(isPresented: $showScoresDashboard) {
                if let gameSessionStore {
                    ScoresDashboardSheet(store: gameSessionStore)
                }
            }
            .sheet(isPresented: $showPartyPersonas) {
                GameNightPersonasSheet(
                    cards: personaCards,
                    gamesPlayedCount: gameSessionStore?.gamesPlayedCount ?? 0
                ) {
                    onEndGame()
                }
            }
            .confirmDialog(
                isPresented: $showRepickConfirm,
                title: "Re-pick roles?",
                message: "This clears all assignments and returns to the lobby.",
                confirmTitle: "Re-pick"
            ) {
                onRepick()
            }
            .confirmDialog(
                isPresented: $showEndGameConfirm,
                title: "End game?",
                message: "Wrap up with party personas, then return home.",
                confirmTitle: "End Game"
            ) {
                personaCards = gameSessionStore?.playerPersonaCards() ?? []
                showPartyPersonas = true
            }
    }
}
