import SwiftUI

/// What a feature shows on the closed pill: a symbol in the left wing, a short text in the
/// right wing, and the glow colour. Features create these and hand them to the pill
/// controller; the pill knows nothing about the feature.
///
/// A **brief** activity (`PillController.show(_:)`) has a duration and disappears by
/// itself. An **ongoing** one (`PillController.setOngoing(_:)`) has none and stays until
/// its feature replaces or clears it, or, if it ends when seen, until the user hovers over
/// or clicks the pill.
nonisolated struct LiveActivity: Equatable {
    /// An SF Symbol name.
    var symbolName: String
    var symbolColor: Color
    /// Short enough for a 34-point wing, such as "73%".
    var text: String
    /// None shows the wings without a glow.
    var glowColor: Color?
    /// Seconds a brief activity stays on the pill. None for an ongoing activity.
    var duration: TimeInterval?
    /// An ongoing activity that is cleared once the user hovers over or clicks the pill.
    var endsWhenSeen = false
}
