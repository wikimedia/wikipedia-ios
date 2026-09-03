import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFAnnouncementsDataControllerTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func fetchFixture() async throws -> [WMFFeedAnnouncement] {
        let service = WMFMockBasicService(jsonResourceName: "feed-announcements-get")
        return try await WMFAnnouncementsDataController(basicService: service).fetchAnnouncements(project: enProject)
    }

    // MARK: - Decoding

    func testFetchDecodesAllAnnouncements() async throws {
        let announcements = try await fetchFixture()
        XCTAssertEqual(announcements.count, 3)
        XCTAssertEqual(announcements.map(\.identifier), ["EN0926FUNDRAISINGIOS", "EN0926SURVEYANDROID", "EN0926ANNOUNCEMENTIOS"])
    }

    func testDecodesFundraisingFields() async throws {
        let announcement = try await fetchFixture()[0]

        XCTAssertEqual(announcement.type, "fundraising")
        XCTAssertEqual(announcement.platforms, ["iOSAppV5"])
        XCTAssertEqual(announcement.countries, ["US", "CA"])
        XCTAssertEqual(announcement.placement, "feed")
        XCTAssertEqual(announcement.text, "<b>Please help</b> keep Wikipedia online and ad-free.")
        XCTAssertEqual(announcement.actionTitle, "Donate now")
        XCTAssertEqual(announcement.actionURL?.absoluteString, "https://donate.wikimedia.org/?uselang=en")
        XCTAssertEqual(announcement.captionHTML, "<a href=\"https://wikimediafoundation.org/privacy\">Privacy policy</a>")
        XCTAssertEqual(announcement.imageURL?.absoluteString, "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Wikipedia_wordmark.svg/640px-Wikipedia_wordmark.svg.png")
        XCTAssertEqual(announcement.imageHeight, 120)
        XCTAssertEqual(announcement.negativeText, "No thanks")
        XCTAssertEqual(announcement.loggedIn, false)
        XCTAssertNil(announcement.readingListSyncEnabled)
        XCTAssertEqual(announcement.beta, false)
        XCTAssertEqual(announcement.domain, "en.wikipedia.org")
        XCTAssertEqual(announcement.percentReceivingExperiment, 50)
        XCTAssertNil(announcement.articleTitles)
        XCTAssertNil(announcement.displayDelay)

        let formatter = DateFormatter.mediaWikiAPIDateFormatter
        XCTAssertEqual(announcement.startTime, formatter.date(from: "2026-09-01T00:00:00Z"))
        XCTAssertEqual(announcement.endTime, formatter.date(from: "2026-12-31T23:59:59Z"))
    }

    func testDecodesOptionalFields() async throws {
        let announcements = try await fetchFixture()

        let survey = announcements[1]
        XCTAssertEqual(survey.articleTitles, ["Cat", "Dog"])
        XCTAssertEqual(survey.displayDelay, 30)
        XCTAssertNil(survey.imageURL)
        XCTAssertNil(survey.beta)

        let plain = announcements[2]
        XCTAssertEqual(plain.imageURL?.absoluteString, "https://upload.wikimedia.org/wikipedia/commons/8/80/Wikipedia-logo-v2.svg", "The `image_url` key is an alias of `image`")
        XCTAssertEqual(plain.countries, [])
        XCTAssertEqual(plain.beta, true)
    }

    // MARK: - Filtering

    func testFilterKeepsOnlyIOSAnnouncements() async throws {
        let filtered = WMFAnnouncementsDataController.filter(try await fetchFixture(), countryCode: "US")
        XCTAssertEqual(filtered.map(\.identifier), ["EN0926FUNDRAISINGIOS", "EN0926ANNOUNCEMENTIOS"])
    }

    func testFilterRemovesAnnouncementsForOtherCountries() async throws {
        let filtered = WMFAnnouncementsDataController.filter(try await fetchFixture(), countryCode: "FR")
        XCTAssertEqual(filtered.map(\.identifier), ["EN0926ANNOUNCEMENTIOS"])
    }

    func testFilterMatchesCountryCodePrefix() async throws {
        let filtered = WMFAnnouncementsDataController.filter(try await fetchFixture(), countryCode: "CA:ON:Toronto")
        XCTAssertEqual(filtered.map(\.identifier), ["EN0926FUNDRAISINGIOS", "EN0926ANNOUNCEMENTIOS"])
    }

    func testFilterWithoutCountryKeepsGlobalAnnouncements() async throws {
        let filtered = WMFAnnouncementsDataController.filter(try await fetchFixture(), countryCode: nil)
        XCTAssertEqual(filtered.map(\.identifier), ["EN0926ANNOUNCEMENTIOS"])
    }

    // MARK: - Codable

    func testCodableRoundTrip() async throws {
        let announcement = try await fetchFixture()[0]
        let data = try JSONEncoder().encode(announcement)
        let decoded = try JSONDecoder().decode(WMFFeedAnnouncement.self, from: data)
        XCTAssertEqual(decoded, announcement)
    }

    func testFetchWithoutServiceThrows() async {
        do {
            _ = try await WMFAnnouncementsDataController(basicService: nil).fetchAnnouncements(project: enProject)
            XCTFail("Expected an error")
        } catch {
            guard case WMFDataControllerError.basicServiceUnavailable = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
