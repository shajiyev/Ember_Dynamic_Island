import SwiftUI

/// A thin rounded bar filled from the left, like Spotify's progress bar. Shared by the
/// Music tab's scrubber and the volume and brightness strip, so the two always look alike.
struct CapsuleBar: View {
    /// How much is filled, 0…1.
    var fill: Double
    /// Dims the fill, for a muted volume.
    var isDimmed = false
    /// Marks this many steps with small dots under the track, one at each step mark with
    /// both ends included; nil shows none.
    var steps: Int? = nil
    /// Makes the bar seekable: called with the fill under the pointer while it is pressed
    /// or dragged (`false`), and once more when it is released (`true`).
    var onSeek: ((_ fill: Double, _ isFinal: Bool) -> Void)? = nil
    /// The text of the label above the pointer for the fill under it, such as "2:08";
    /// nil shows no label. Only on a seekable bar.
    var hoverLabel: ((_ fill: Double) -> String)? = nil

    static let trackHeight: CGFloat = 4
    static let trackColor = Color(white: 0x4D / 255)
    /// A seekable bar is taller than its track, so it is easy to grab.
    private static let grabHeight: CGFloat = 12

    /// The pointer's x over the bar while it is on it, nil otherwise.
    @State private var hoverX: CGFloat?
    @State private var isDragging = false

    /// The pointer is on a seekable bar, or dragging it: the preview and the label show.
    private var showsHover: Bool { onSeek != nil && (hoverX != nil || isDragging) }

    /// The fill under a pointer `x` points from the bar's left edge, kept within 0…1.
    static func fill(atX x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return min(max(Double(x / width), 0), 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            track
            if let steps {
                stepDots(steps)
            }
        }
    }

    private var track: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let current = min(max(fill, 0), 1)
            let pointerFill = hoverX.map { Self.fill(atX: $0, width: width) }
            ZStack(alignment: .leading) {
                Capsule().fill(Self.trackColor)
                if showsHover, let pointerFill, pointerFill > current {
                    Capsule().fill(.white.opacity(0.5))
                        .frame(width: width * pointerFill)
                }
                Capsule().fill(.white.opacity(isDimmed ? 0.4 : 1))
                    .frame(width: width * current)
            }
            .frame(height: Self.trackHeight)
            .frame(maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                if showsHover, let pointerFill, let hoverLabel {
                    label(hoverLabel(pointerFill))
                        .offset(x: width * pointerFill, y: Self.trackHeight / 2 - 6)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let point): hoverX = point.x
                case .ended: hoverX = nil
                }
            }
            .gesture(seekGesture(width: width), including: onSeek == nil ? .none : .all)
        }
        .frame(height: onSeek == nil ? Self.trackHeight : Self.grabHeight)
    }

    /// The time box, centred on x = 0 with its bottom at y = 0, so the caller only offsets it.
    private func label(_ text: String) -> some View {
        Color.clear.frame(width: 0, height: 0)
            .overlay(alignment: .bottom) {
                Text(text)
                    .font(.system(size: 10, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.17)))
                    .fixedSize()
                    .allowsHitTesting(false)
            }
    }

    private func seekGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged {
                isDragging = true
                hoverX = $0.location.x
                onSeek?(Self.fill(atX: $0.location.x, width: width), false)
            }
            .onEnded {
                isDragging = false
                onSeek?(Self.fill(atX: $0.location.x, width: width), true)
            }
    }

    private func stepDots(_ steps: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(0...steps, id: \.self) { step in
                if step > 0 {
                    Spacer(minLength: 0)
                }
                Circle()
                    .fill(.white.opacity(0.25))
                    .frame(width: 2, height: 2)
            }
        }
    }
}
