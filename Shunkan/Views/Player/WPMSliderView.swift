import SwiftUI

struct WPMSliderView: View {
    @Binding var wpm: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("100")
                Spacer()
                Text("WPM")
                    .foregroundStyle(.blue)
                Spacer()
                Text("900")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Slider(
                value: Binding(
                    get: { Double(wpm) },
                    set: { wpm = Int($0) }
                ),
                in: 100...900,
                step: 10
            )
            .tint(.blue)

            Text("\(wpm) WPM")
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .padding(.horizontal, 40)
    }
}
