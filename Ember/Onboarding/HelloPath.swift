import SwiftUI

/// The word "hello" in joined handwriting, as one line of curves, so it can be written on
/// from left to right (`trim`). Ember's own drawing; drawn in a 100 × 40 box, y down.
nonisolated enum HelloPath {
    /// Where the line starts.
    private static let start = CGPoint(x: 2, y: 33)
    /// Each curve as its two control points and its end: x1, y1, x2, y2, x, y.
    private static let numbers: [[CGFloat]] = [
        // h
        [7, 31, 15, 25, 15, 14],   // rises into the loop without a corner
        [15, 1, 9, 1, 9, 7],
        [9, 15, 10, 24, 10, 32],
        [11, 25, 14, 20, 18, 20],
        [22, 20, 22, 25, 22, 29],
        [22, 33, 26, 33, 29, 29],
        // e
        [32, 26, 37, 23, 37, 20],
        [37, 17, 31, 17, 31, 23],
        [31, 29, 34, 32, 38, 32],
        [41, 32, 43, 29, 45, 26],
        // l
        [48, 21, 52, 13, 52, 7],
        [52, 1, 45, 1, 45, 7],
        [45, 15, 46, 26, 47, 30],
        [48, 33, 52, 32, 55, 27],
        // l
        [58, 21, 62, 13, 62, 7],
        [62, 1, 55, 1, 55, 7],
        [55, 15, 56, 26, 57, 30],
        [58, 33, 62, 32, 65, 27],
        // o, ending in a flourish
        [67, 23, 70, 20, 73, 20],
        [77, 20, 78, 25, 77, 28],
        [76, 32, 71, 33, 69, 30],
        [67, 27, 69, 21, 74, 21],
        [78, 21, 82, 22, 86, 20],
    ]
    private static let curves: [(CGPoint, CGPoint, CGPoint)] = numbers.map {
        (CGPoint(x: $0[0], y: $0[1]), CGPoint(x: $0[2], y: $0[3]), CGPoint(x: $0[4], y: $0[5]))
    }
    /// The area the line covers in the box.
    private static let extent = CGRect(x: 2, y: 1, width: 84, height: 32)

    /// The line fitted into `rect` without stretching, centred.
    static func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / extent.width, rect.height / extent.height)
        let origin = CGPoint(x: rect.midX - extent.width * scale / 2, y: rect.midY - extent.height * scale / 2)
        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + (point.x - extent.minX) * scale, y: origin.y + (point.y - extent.minY) * scale)
        }
        var path = Path()
        path.move(to: place(start))
        for (control1, control2, end) in curves {
            path.addCurve(to: place(end), control1: place(control1), control2: place(control2))
        }
        return path
    }
}

/// `HelloPath` as a shape, so SwiftUI can trim and stroke it.
struct HelloShape: Shape {
    func path(in rect: CGRect) -> Path { HelloPath.path(in: rect) }
}
