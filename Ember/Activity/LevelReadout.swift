import Foundation

/// What the pill shows for a volume or brightness change: a symbol, a bar and a short text,
/// in a strip below the pill's current shape. Features create these and hand them to
/// `PillController.showLevel(_:)`; the pill knows nothing about volume or brightness.
nonisolated struct LevelReadout: Equatable {
    /// An SF Symbol name.
    var symbolName: String
    /// Short, such as "62%" or "Muted".
    var text: String
    /// How much of the bar is filled, 0…1.
    var fill: Double
    /// The bar marks this many steps with dots: one key press moves one dot.
    var steps: Int
    /// Dims the bar's fill, for a muted volume.
    var isDimmed = false
    /// Seconds the strip stays after this readout.
    var duration: TimeInterval
}
