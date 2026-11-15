import AppKit
import Foundation

/// Where Share Feedback leads, from the menu and Settings → Feedback. Not chosen yet: while
/// `url` is nil, both buttons are greyed out. Choosing it means filling in `url`.
enum Feedback {
    static let url: URL? = nil

    static func open() {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}
