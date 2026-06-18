import SwiftUI

struct TimerView: View {
    let timeLabel: String

    var body: some View {
        Text(timeLabel)
            .font(.system(size: 56, weight: .bold, design: .rounded))
            .monospacedDigit()
            .accessibilityLabel("Timer \(timeLabel)")
    }
}
