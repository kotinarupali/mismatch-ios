import SwiftUI

struct AvatarView: View {
    let name: String
    let color: AvatarColor
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.avatar(color).opacity(0.85))
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(name)
    }
}

#Preview {
    AvatarView(name: "Jordan", color: .blue)
}
