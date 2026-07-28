import XCTest
@testable import WMF

class WidgetSampleContentTests: XCTestCase {

	func testFeaturedArticleWidgetSampleContentDecoding() throws {
		let sampleContent = WidgetFeaturedContent.previewContent()

		// Confirm JSON payload decodes correctly
		XCTAssertNotNil(sampleContent, "Could not decode Featured Article Widget sample content JSON")

		// Confirm content for display is available
		XCTAssertNotNil(sampleContent?.featuredArticle?.displayTitle, "Featured Article Widget sample display title unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.thumbnailImageSource?.data, "Featured Article Widget sample image unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.contentURL.desktop.page, "Featured Article Widget sample content URL unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.extract, "Featured Article Widget sample extract unavailable")
		XCTAssertNotNil(sampleContent?.featuredArticle?.description, "Featured Article Widget sample description unavailable")
	}

    func testFeaturedContentDecodingToleratesMissingViewHistory() throws {
        // Regression test: the feed API omits view_history for some most-read
        // articles (typically newly trending ones). Decoding must not fail for
        // the whole payload — it previously broke the Featured Article,
        // Picture of the Day, and Top Read widgets together.
        let data = try XCTUnwrap(wmf_bundle().wmf_data(fromContentsOfFile: "FeedDayResponseMissingViewHistory", ofType: "json"))

        let content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: data)

        XCTAssertNotNil(content.featuredArticle, "Today's featured article should decode despite a mostread article without view_history")
        XCTAssertNotNil(content.pictureOfTheDay, "Picture of the day should decode despite a mostread article without view_history")
        let articles = try XCTUnwrap(content.topRead?.elements)
        XCTAssertEqual(articles.count, 2)
        XCTAssertNotNil(articles[0].viewHistory)
        XCTAssertNotNil(articles[0].views)
        XCTAssertNil(articles[1].viewHistory, "article without view_history should decode with nil history")
    }

    // MARK: - Top Read cache fallback

    func testTopReadCacheFallbackFlagIsNotPersisted() throws {
        var topRead = try topRead(dateString: "2026-07-27Z")
        XCTAssertFalse(topRead.isFromCacheFallback, "decoded content should never be marked as fallback")

        topRead.isFromCacheFallback = true
        let roundTripped = try JSONDecoder().decode(WidgetTopRead.self, from: JSONEncoder().encode(topRead))
        XCTAssertFalse(roundTripped.isFromCacheFallback, "isFromCacheFallback is runtime-only and must not survive the cache round-trip")
    }

    func testTopReadIsCurrentUsesLocalDate() throws {
        // 15:00 UTC on Jul 28 is already 01:00 on Jul 29 in Sydney, so Sydney's "yesterday"
        // is Jul 28 while UTC's is still Jul 27.
        let now = try utcDate(year: 2026, month: 7, day: 28, hour: 15, minute: 0)
        let sydney = calendar(timeZoneIdentifier: "Australia/Sydney")
        XCTAssertTrue(WidgetController.shared.topReadIsCurrent(try topRead(dateString: "2026-07-28Z"), now: now, calendar: sydney))
        XCTAssertFalse(WidgetController.shared.topReadIsCurrent(try topRead(dateString: "2026-07-27Z"), now: now, calendar: sydney))

        // At the same instant it is 09:00 on Jul 28 in Calgary, where Jul 27 is current.
        let calgary = calendar(timeZoneIdentifier: "America/Edmonton")
        XCTAssertTrue(WidgetController.shared.topReadIsCurrent(try topRead(dateString: "2026-07-27Z"), now: now, calendar: calgary))
    }

    func testTopReadIsNotCurrentForOlderOrMissingData() throws {
        let now = try utcDate(year: 2026, month: 7, day: 28, hour: 15, minute: 0)
        let calgary = calendar(timeZoneIdentifier: "America/Edmonton")
        XCTAssertFalse(WidgetController.shared.topReadIsCurrent(try topRead(dateString: "2026-07-26Z"), now: now, calendar: calgary))
        XCTAssertFalse(WidgetController.shared.topReadIsCurrent(try topRead(dateString: nil), now: now, calendar: calgary))
        XCTAssertFalse(WidgetController.shared.topReadIsCurrent(nil, now: now, calendar: calgary))
    }

    // MARK: - Top Read publication date

    func testExpectedTopReadPublicationDateEastOfUTC() throws {
        // Midnight in Sydney (UTC+10) on Jul 29 is 14:00 UTC on Jul 28; the local date's
        // most-read data is only published within 03:00–03:30 UTC on Jul 29.
        let sydneyMidnight = try utcDate(year: 2026, month: 7, day: 28, hour: 14, minute: 5)
        let publication = try XCTUnwrap(
            WidgetController.expectedTopReadPublicationDate(
                after: sydneyMidnight,
                calendar: calendar(timeZoneIdentifier: "Australia/Sydney")
            )
        )
        XCTAssertGreaterThanOrEqual(publication, try utcDate(year: 2026, month: 7, day: 29, hour: 3, minute: 0))
        XCTAssertLessThan(publication, try utcDate(year: 2026, month: 7, day: 29, hour: 3, minute: 30))
    }

    func testExpectedTopReadPublicationDateWestOfUTCAfterPublication() throws {
        // Midnight in Calgary (UTC-6) on Jul 28 is 06:10 UTC, past the 03:00–03:30 UTC
        // publication window for the local date — the data should already exist.
        let calgaryMidnight = try utcDate(year: 2026, month: 7, day: 28, hour: 6, minute: 10)
        XCTAssertNil(
            WidgetController.expectedTopReadPublicationDate(
                after: calgaryMidnight,
                calendar: calendar(timeZoneIdentifier: "America/Edmonton")
            )
        )
    }

    func testExpectedTopReadPublicationDateNonGregorianCalendar() throws {
        // A Buddhist-calendar year (2569) must not be reinterpreted as a Gregorian year.
        var buddhistBangkok = Calendar(identifier: .buddhist)
        buddhistBangkok.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Bangkok"))

        let beforePublication = try utcDate(year: 2026, month: 7, day: 28, hour: 1, minute: 0)
        let publication = try XCTUnwrap(
            WidgetController.expectedTopReadPublicationDate(after: beforePublication, calendar: buddhistBangkok)
        )
        XCTAssertLessThan(publication.timeIntervalSince(beforePublication), 60 * 60 * 24, "publication date should be within a day, not centuries away")

        let afterPublication = try utcDate(year: 2026, month: 7, day: 28, hour: 14, minute: 5)
        XCTAssertNil(WidgetController.expectedTopReadPublicationDate(after: afterPublication, calendar: buddhistBangkok))
    }

    // MARK: - Helpers

    private func topRead(dateString: String?) throws -> WidgetTopRead {
        let dateField = dateString.map { "\"date\": \"\($0)\"," } ?? ""
        let json = "{\(dateField)\"articles\": []}"
        return try JSONDecoder().decode(WidgetTopRead.self, from: Data(json.utf8))
    }

    private func calendar(timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        return calendar
    }

    private func utcDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        return try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
    }
}
