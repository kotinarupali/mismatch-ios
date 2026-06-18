import SwiftUI

extension View {
    func hostGameMenu(
        gameSessionStore: GameSessionStore? = nil,
        onRepick: @escaping () -> Void,
        onEndSession: @escaping () -> Void,
        onCheckPlayerRole: (() -> Void)? = nil
    ) -> some View {
        modifier(HostGameMenuModifier(
            gameSessionStore: gameSessionStore,
            onRepick: onRepick,
            onEndSession: onEndSession,
            onCheckPlayerRole: onCheckPlayerRole
        ))
    }
}

private struct HostGameMenuModifier: ViewModifier {
    @State private var showRepickConfirm = false
    @State private var showEndSessionConfirm = false
    @State private var showScoresDashboard = false

    let gameSessionStore: GameSessionStore?
    let onRepick: () -> Void
    let onEndSession: () -> Void
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
                            showEndSessionConfirm = true
                        } label: {
                            Label("End Game Night", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppColor.label)
                            .accessibilityLabel("Game options")
                    }
                }
            }
            .sheet(isPresented: $showScoresDashboard) {
                if let gameSessionStore {
                    ScoresDashboardSheet(store: gameSessionStore)
                }
            }
            .confirmDialog(
                isPresented: $showRepickConfirm,
                title: "Re-pick roles?",
                message: "Everyone picks cards again. Role assignments stay the same.",
                confirmTitle: "Re-pick"
            ) {
                onRepick()
            }
            .confirmDialog(
                isPresented: $showEndSessionConfirm,
                title: "End game night?",
                message: "Wrap up with tonight's leaderboard. You can play again with the same group or start fresh.",
                confirmTitle: "End Game Night"
            ) {
                onEndSession()
            }
    }
}
