import Foundation
import Testing
@testable import Ember

struct AboutInfoTests {
    @Test func theVersionShowsTheReleaseAndTheBuild() {
        #expect(AboutInfo.versionText(info: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "12"]) == "Version 1.0 (12)")
        #expect(AboutInfo.versionText(info: ["CFBundleShortVersionString": "1.0"]) == "Version 1.0")
        #expect(AboutInfo.versionText(info: [:]) == "Version unknown")
    }

    @Test func theLinksGoToTheWebsiteTheCodeAndTheLicence() {
        #expect(AboutInfo.website.absoluteString == "https://www.getember.online")
        #expect(AboutInfo.github.absoluteString == "https://github.com/shajiyev/Ember_Dynamic_Island")
        #expect(AboutInfo.license.absoluteString == "https://github.com/shajiyev/Ember_Dynamic_Island/blob/main/LICENSE")
    }
}
