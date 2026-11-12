import SwiftUI

/// Four bars that bounce while music plays. A looping animation, not real audio levels.
struct EqualizerView: View {
    let color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { bar in
                    let wave = abs(sin(time * (2.2 + Double(bar) * 0.7) + Double(bar)))
                    Capsule()
                        .fill(color)
                        .frame(width: 2.5, height: 4 + 8 * wave)
                }
            }
            .frame(height: 12)
        }
    }
}
