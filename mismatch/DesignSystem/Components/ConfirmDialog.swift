import SwiftUI

struct ConfirmDialog: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmTitle: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(title, isPresented: $isPresented, titleVisibility: .visible) {
                Button(confirmTitle, role: .destructive, action: onConfirm)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    func confirmDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(ConfirmDialog(
            isPresented: isPresented,
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            onConfirm: onConfirm
        ))
    }
}
