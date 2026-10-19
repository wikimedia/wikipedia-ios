import XCTest

@testable import WMFData
@testable import WMFDataMocks

/// Tests for the values that the Explore feed derives from the feed and on-this-day responses.
final class WMFFeedDerivedValuesTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    // MARK: - News story date

    func testStoryMonthAndDayParsesTheLeadingComment() throws {
        let date = WMFFeedNewsItem.monthAndDay(fromStoryHTML: "<!--Aug 12--><b>Something</b> happened.")
        let components = try XCTUnwrap(date).utcComponents

        XCTAssertEqual(components.month, 8)
        XCTAssertEqual(components.day, 12)
    }

    func testStoryMonthAndDayIsNilWithoutComment() {
        XCTAssertNil(WMFFeedNewsItem.monthAndDay(fromStoryHTML: "<b>Something</b> happened."))
        XCTAssertNil(WMFFeedNewsItem.monthAndDay(fromStoryHTML: nil))
    }

    func testStoryMonthAndDayFromFixture() async throws {
        let service = WMFMockBasicService(jsonResourceName: "feed-featured-2025-12-11-get")
        let response = try await WMFFeedDataController(basicService: service).fetchFeed(project: enProject, date: Date())
        let news = try XCTUnwrap(response.news?.first)

        if news.story?.hasPrefix("<!--") == true {
            XCTAssertNotNil(news.storyMonthAndDay)
        } else {
            XCTAssertNil(news.storyMonthAndDay)
        }
    }

    // MARK: - On this day score

    func testScoreOutsideEnglishIsTheImageCount() {
        XCTAssertEqual(WMFOnThisDayEvent.score(text: "Ten people were killed.", imageCount: 3, languageCode: "de"), 3)
    }

    func testScoreInEnglishWeightsImagesAndSubtractsDeaths() {
        XCTAssertEqual(WMFOnThisDayEvent.score(text: "A bridge opens.", imageCount: 5, languageCode: "en"), 1.0, accuracy: 0.0001)
        XCTAssertEqual(WMFOnThisDayEvent.score(text: "Ten people were killed in an explosion.", imageCount: 5, languageCode: "en"), -1.0, accuracy: 0.0001)
    }

    func testDeathMatchCount() {
        XCTAssertEqual(WMFOnThisDayEvent.deathMatchCount(in: "The bomb killed the assassin."), 3)
        XCTAssertEqual(WMFOnThisDayEvent.deathMatchCount(in: "Killer whales are dolphins."), 0, "Whole words only")
        XCTAssertEqual(WMFOnThisDayEvent.deathMatchCount(in: nil), 0)
    }

    func testEventScoreCountsPagesWithImages() async throws {
        let service = WMFMockBasicService(jsonResourceName: "onthisday-events-02-21-get")
        let response = try await WMFOnThisDayDataController(basicService: service).fetchOnThisDay(project: enProject, month: 2, day: 21)
        let event = try XCTUnwrap(response.events.first)
        let imageCount = event.pages.filter { $0.originalImage != nil || $0.thumbnail != nil }.count

        XCTAssertEqual(event.score(languageCode: "fr"), Double(imageCount))
    }
}

private extension Date {
    var utcComponents: DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.dateComponents([.month, .day], from: self)
    }
}
