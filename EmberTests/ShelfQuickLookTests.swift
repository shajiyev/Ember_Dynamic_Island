import AppKit
import Testing
@testable import Ember

struct ShelfQuickLookTests {
    @Test func quickLookCanShowOverAFullScreenApp() {
        // Like the pill's window: it joins the full-screen app's space instead of the desktop's.
        #expect(ShelfQuickLook.spaceBehavior.contains(.fullScreenAuxiliary))
        #expect(ShelfQuickLook.spaceBehavior.contains(.canJoinAllSpaces))
    }
}
