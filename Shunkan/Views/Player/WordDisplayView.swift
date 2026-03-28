import SwiftUI

struct WordDisplayView: View {
    let word: String
    let dimmed: Bool

    private var textColor: Color {
        dimmed ? Color(.systemGray4) : .white
    }

    var body: some View {
        let orpIndex = ORPCalculator.optimalIndex(for: word)
        let chars = Array(word)

        HStack(spacing: 0) {
            if orpIndex > 0 {
                Text(String(chars[0..<orpIndex]))
                    .foregroundStyle(textColor)
            }

            Text(orpIndex < chars.count ? String(chars[orpIndex]) : "")
                .foregroundStyle(textColor)

            if orpIndex + 1 < chars.count {
                Text(String(chars[(orpIndex + 1)...]))
                    .foregroundStyle(textColor)
            }
        }
        .font(.system(size: 48, weight: .semibold, design: .default))
        .monospaced()
    }
}
