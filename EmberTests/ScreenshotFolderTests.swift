import Foundation
import Testing
@testable import Ember

struct ScreenshotFolderTests {
    private let home = URL(filePath: "/example/home", directoryHint: .isDirectory)

    @Test func screenshotsGoToTheDesktopUnlessMovedElsewhere() {
        #expect(ScreenshotFolder.url(savedLocation: nil, home: home).path == "/example/home/Desktop")
        #expect(ScreenshotFolder.url(savedLocation: "", home: home).path == "/example/home/Desktop")
    }

    @Test func aChosenFolderIsUsedWithOrWithoutATilde() {
        #expect(ScreenshotFolder.url(savedLocation: "~/Pictures/Screenshots", home: home).path
                == "/example/home/Pictures/Screenshots")
        #expect(ScreenshotFolder.url(savedLocation: "/Volumes/Shots", home: home).path == "/Volumes/Shots")
    }

    @Test func macOSsFloatingThumbnailIsOnUnlessSwitchedOff() {
        #expect(ScreenshotThumbnail.isOn(saved: nil))
        #expect(ScreenshotThumbnail.isOn(saved: true))
        #expect(!ScreenshotThumbnail.isOn(saved: false))
        #expect(!ScreenshotThumbnail.isOn(saved: 0))
    }
}
