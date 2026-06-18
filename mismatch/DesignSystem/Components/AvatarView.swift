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
                .fill(
                    LinearGradient(
                        colors: [AppColor.avatar(color), AppColor.avatar(color).opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: AppColor.avatar(color).opacity(0.4), radius: size * 0.12, y: size * 0.06)
        .accessibilityLabel(name)
    }
}
