import SwiftUI

/// What a feature shows on the closed pill: a symbol in the left wing, a short text in
/// the right wing, and the glow colour, for a limited time. Features create these and
/// hand them to `PillController.show(_:)`; the pill knows nothing about the feature.
nonisolated struct LiveActivity: Equatable {
    /// An SF Symbol name.
    var symbolName: String
    var symbolColor: Color
    /// Short enough for a 34-point wing, such as "73%".
    var text: String
    var glowColor: Color
    /// Seconds the activity stays on the pill.
    var duration: TimeInterval
}
