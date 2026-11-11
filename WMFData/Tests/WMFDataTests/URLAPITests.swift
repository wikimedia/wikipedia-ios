import Foundation
import Testing
@testable import WMFData

@Suite
struct URLAPITests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    // MARK: - String.percentEncodedPageTitleForPathComponents

    @Test func percentEncodedPageTitleReplacesSpacesWithUnderscores() {
        #expect("San Francisco".percentEncodedPageTitleForPathComponents == "San_Francisco")
    }

    @Test func percentEncodedPageTitleEncodesSlash() {
        #expect("AC/DC".percentEncodedPageTitleForPathComponents == "AC%2FDC")
    }

    @Test func percentEncodedPageTitleEncodesReservedCharacters() {
        #expect("What?".percentEncodedPageTitleForPathComponents == "What%3F")
        #expect("C#".percentEncodedPageTitleForPathComponents == "C%23")
    }

    @Test func percentEncodedPageTitleComposesBeforeEncoding() {
        #expect("Beyonce\u{0301}".percentEncodedPageTitleForPathComponents == "Beyonc%C3%A9")
    }

    // MARK: - URL.mediaWikiRestAPIURL

    @Test func mediaWikiRestAPIURLKeepsSlashTitleInOneSegment() throws {
        let url = try #require(URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["attribution", "v0-beta", "pages", "AC/DC", "signals"]))
        #expect(url.absoluteString == "https://en.wikipedia.org/w/rest.php/attribution/v0-beta/pages/AC%2FDC/signals")
    }

    @Test func mediaWikiRestAPIURLEncodesReservedCharacters() throws {
        let url = try #require(URL.mediaWikiRestAPIURL(project: project, additionalPathComponents: ["growthexperiments", "v0", "user-impact", "#123"]))
        #expect(url.absoluteString == "https://en.wikipedia.org/w/rest.php/growthexperiments/v0/user-impact/%23123")
    }
}
