import SwiftUI

struct GameFinalResultsSection: View {
    let insiderWord: String
    let mismatchWord: String

    var body: some View {
        VStack(spacing: 12) {
            OutcomeCard(title: "Insider word", value: insiderWord, icon: "checkmark.seal.fill")
            OutcomeCard(title: "Mismatch word", value: mismatchWord, icon: "xmark.seal.fill")
        }
    }
}
