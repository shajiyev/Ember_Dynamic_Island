import EventKit
import Testing
@testable import Ember

struct PermissionsTests {
    @Test func calendarAccessIsAllowedOnlyWithFullAccess() {
        #expect(AppPermission.status(calendar: .fullAccess) == .allowed)
        #expect(AppPermission.status(calendar: .notDetermined) == .notAsked)
        #expect(AppPermission.status(calendar: .denied) == .notAllowed)
        #expect(AppPermission.status(calendar: .writeOnly) == .notAllowed)
    }

    @Test func automationIsReadFromMacOSsAnswer() {
        #expect(AppPermission.status(automation: 0) == .allowed)
        #expect(AppPermission.status(automation: -1744) == .notAsked)     // would need the user's consent
        #expect(AppPermission.status(automation: -1743) == .notAllowed)   // not permitted
        #expect(AppPermission.status(automation: -600) == .unknown)       // the player is not open
    }

    @Test func eachPermissionSaysWhatUsesItAndOpensItsPageInSystemSettings() {
        #expect(AppPermission.calendar.usedBy == "Show Calendar Events")
        #expect(AppPermission.accessibility.usedBy == "Volume & Brightness")
        #expect(AppPermission.calendar.settingsURL.absoluteString
                == "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        #expect(AppPermission.spotify.settingsURL.absoluteString
                == "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    @Test func everyStatusHasPlainWords() {
        #expect(PermissionStatus.allowed.title == "Allowed")
        #expect(PermissionStatus.notAsked.title == "Not asked yet")
        #expect(PermissionStatus.notAllowed.title == "Not allowed")
        #expect(PermissionStatus.unknown.title == "Open the player to check")
        #expect(PermissionStatus.askedWhenTurnedOn.title == "macOS asks when you turn it on")
    }

    @Test func theScreenshotsFolderIsListedButCannotBeReadWithoutAsking() {
        #expect(AppPermission.screenshotFolder.usedBy == "Add screenshots to the shelf")
        #expect(AppPermission.screenshotFolder.currentStatus == .askedWhenTurnedOn)
        #expect(AppPermission.screenshotFolder.settingsURL.absoluteString
                == "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")
    }
}
