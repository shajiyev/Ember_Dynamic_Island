import Foundation

/// A colour a feature lets the user choose on its own Settings page. With none chosen the
/// feature keeps its own: the song's cover, the timer's orange, Time's up's amber, each
/// event's calendar colour, the glow colour for the shelf, each battery alert's green,
/// yellow or red.
nonisolated enum FeatureColor: String, CaseIterable {
    case music
    case timer
    case timesUp
    case calendar
    case shelf
    case batteryPluggedIn
    case batteryUnplugged
    case batteryLow
    case batteryVeryLow
}
