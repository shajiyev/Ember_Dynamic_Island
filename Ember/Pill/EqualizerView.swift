import AppKit
import SwiftUI

/// Four bars that bounce while music plays. A looping animation, not real audio levels.
///
/// Drawn with Core Animation: each bar's bounce is handed to macOS once and played by the
/// system at the display's own rate, so Ember does no work per frame. (Redrawn by SwiftUI 24
/// times a second it cost about 6.5% CPU for as long as music played, measured 2026-11-23.)
struct EqualizerView: NSViewRepresentable {
    let color: Color

    /// Each bar's bounce: how long one loop takes, and where it starts, so the four never
    /// move together.
    private static let bars: [(duration: CFTimeInterval, offset: CFTimeInterval)] = [
        (0.95, 0.0), (0.75, 0.3), (1.1, 0.55), (0.85, 0.15),
    ]
    static let barWidth: CGFloat = 2.5
    static let spacing: CGFloat = 2
    static let height: CGFloat = 12
    static let lowest: CGFloat = 4

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        for (index, bar) in Self.bars.enumerated() {
            let layer = CALayer()
            layer.cornerRadius = Self.barWidth / 2
            layer.frame = CGRect(x: CGFloat(index) * (Self.barWidth + Self.spacing), y: 0,
                                 width: Self.barWidth, height: Self.height)
            layer.add(Self.bounce(duration: bar.duration, offset: bar.offset), forKey: "bounce")
            view.layer?.addSublayer(layer)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        let color = NSColor(color).cgColor
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)   // a new song's colour fades in
        view.layer?.sublayers?.forEach { $0.backgroundColor = color }
        CATransaction.commit()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSView, context: Context) -> CGSize? {
        CGSize(width: CGFloat(Self.bars.count) * Self.barWidth + CGFloat(Self.bars.count - 1) * Self.spacing,
               height: Self.height)
    }

    /// A bar growing from its lowest to full height and back, around its middle, for ever.
    private static func bounce(duration: CFTimeInterval, offset: CFTimeInterval) -> CAKeyframeAnimation {
        let low = lowest / height
        let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
        animation.values = [low, 1, low * 1.6, 0.85, low]
        animation.keyTimes = [0, 0.3, 0.5, 0.75, 1]
        animation.calculationMode = .cubic
        animation.duration = duration
        animation.timeOffset = offset
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        return animation
    }
}
