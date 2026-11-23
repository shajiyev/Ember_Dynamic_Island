import Foundation
import Testing
@testable import Ember

struct FeedbackTests {
    private let mail = Feedback.mailURL(appVersion: "Version 1.0 (2)", macOS: "Version 26.6.2 (Build 25G100)")

    @Test func shareFeedbackWritesToEmbersOwnAddress() {
        #expect(mail.scheme == "mailto")
        #expect(mail.absoluteString.hasPrefix("mailto:ember.share.feedback@gmail.com?"))
    }

    @Test func theEmailComesWithASubjectAndTheVersionsForBugReports() throws {
        let items = try #require(URLComponents(url: mail, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(items.first { $0.name == "subject" }?.value == "Ember feedback")
        let body = try #require(items.first { $0.name == "body" }?.value)
        #expect(body.contains("Ember Version 1.0 (2)"))
        #expect(body.contains("macOS Version 26.6.2 (Build 25G100)"))
    }
}
