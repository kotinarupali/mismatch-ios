import SwiftUI

extension View {
    func hostGameMenu(
        onRepick: @escaping () -> Void,
        onEndGame: @escaping () -> Void,
        onCheckPlayerRole: (() -> Void)? = nil
    ) -> some View {
        modifier(HostGameMenuModifier(
            onRepick: onRepick,
            onEndGame: onEndGame,
            onCheckPlayerRole: onCheckPlayerRole
        ))
    }
}

private struct HostGameMenuModifier: ViewModifier {
    @State private var showRepickConfirm = false
    @State private var showEndGameConfirm = false

    let onRepick: () -> Void
    let onEndGame: () -> Void
    let onCheckPlayerRole: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
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
                message: "This ends the session and returns to the home screen.",
                confirmTitle: "End Game"
            ) {
                onEndGame()
            }
    }
}
