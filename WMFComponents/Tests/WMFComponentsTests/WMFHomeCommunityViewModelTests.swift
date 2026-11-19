import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFNativeLocalizations

final class WMFHomeCommunityViewModelTests: XCTestCase {

    private let english = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let arabic = WMFProject.wikipedia(WMFLanguage(languageCode: "ar", languageVariantCode: nil))

    private let allOn = WMFCommunityModuleVisibility(featuredArticle: true, topRead: true, inTheNews: true, onThisDay: true, pictureOfDay: true)

    /// A feed with content for every module.
    private let fullFeedJSON = """
    {
      "tfa": { "title": "Black_hole", "displaytitle": "Black hole" },
      "mostread": { "articles": [ { "title": "Octopus", "normalizedtitle": "Octopus" } ] },
      "image": { "title": "File:Sky.jpg", "thumbnail": { "source": "https://upload.wikimedia.org/sky.jpg", "width": 640, "height": 480 } },
      "news": [ { "story": "A story" } ]
    }
    """

    private func feed(_ json: String) throws -> WMFFeedAPIResponse {
        try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(json.utf8))
    }

    private func onThisDay(eventCount: Int) throws -> WMFOnThisDayResponse {
        let events = (0..<eventCount).map { _ in #"{ "text": "Something happened", "year": 2013, "pages": [] }"# }
        return try JSONDecoder().decode(WMFOnThisDayResponse.self, from: Data(#"{ "events": [\#(events.joined(separator: ","))] }"#.utf8))
    }

    private func page(feedJSON: String? = nil, onThisDayEvents: Int = 1, date: Date = Date(), project: WMFProject? = nil, now: Date = Date()) throws -> WMFHomeCommunityViewModel {
        let response = WMFCommunityResponse(
            date: date,
            feedResponse: try feed(feedJSON ?? fullFeedJSON),
            onThisDay: try onThisDay(eventCount: onThisDayEvents)
        )
        return WMFHomeCommunityViewModel(response: response, project: project ?? english, now: now)
    }

    // MARK: - Module order and visibility

    /// The ticket's order, which Android uses too.
    func testModulesFollowTheFeedOrder() throws {
        let page = try page()
        XCTAssertEqual(page.visibleModules(visibility: allOn, hiddenCardKeys: []), [.featuredArticle, .topRead, .inTheNews, .onThisDay, .pictureOfDay])
    }

    func testModulesWithoutContentInTheWikiAreHidden() throws {
        let page = try page(feedJSON: #"{ "tfa": { "title": "Black_hole" } }"#, onThisDayEvents: 0)
        XCTAssertEqual(page.visibleModules(visibility: allOn, hiddenCardKeys: []), [.featuredArticle])
    }

    func testModulesTurnedOffAreHidden() throws {
        let page = try page()
        var visibility = allOn
        visibility.topRead = false
        visibility.pictureOfDay = false
        XCTAssertEqual(page.visibleModules(visibility: visibility, hiddenCardKeys: []), [.featuredArticle, .inTheNews, .onThisDay])
    }

    func testHiddenCardsAreHidden() throws {
        let page = try page()
        let hidden: Set<String> = [page.topReadHideKey, try XCTUnwrap(page.featuredArticleHideKey)]
        XCTAssertEqual(page.visibleModules(visibility: allOn, hiddenCardKeys: hidden), [.inTheNews, .onThisDay, .pictureOfDay])
    }

    /// The key is saved and read again on the next launch, so it must not depend on the process.
    func testPictureOfTheDayHideKeyIsTheFileTitle() throws {
        XCTAssertEqual(try page().pictureOfDayHideKey, "picture_of_day_File:Sky.jpg")
    }

    func testPictureOfTheDayHideKeyFallsBackToTheThumbnail() throws {
        let page = try page(feedJSON: #"{ "image": { "thumbnail": { "source": "https://upload.wikimedia.org/sky.jpg" } } }"#)
        XCTAssertEqual(page.pictureOfDayHideKey, "picture_of_day_https://upload.wikimedia.org/sky.jpg")
    }

    func testANewsStoryKeepsTheArticleItOpens() throws {
        let page = try page(feedJSON: #"{ "news": [ { "story": "A story", "links": [ { "title": "Black_hole" } ] } ] }"#)
        XCTAssertEqual(page.newsItems.first?.articleTitle, "Black_hole")
    }

    func testOnThisDayWithNoEventsHasNoItems() throws {
        XCTAssertNil(try page(onThisDayEvents: 0).onThisDayItems)
    }

    // MARK: - Date header

    func testTodaysPageSaysToday() throws {
        let now = Date()
        let page = try page(date: now, now: now)
        let formatted = DateFormatter.wmfMediumDateFormatter(languageCode: nil).string(from: now)
        XCTAssertEqual(page.date, "Today - \(formatted)")
    }

    func testAnEarlierPageShowsOnlyItsDate() throws {
        let now = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: now))
        let page = try page(date: yesterday, now: now)
        XCTAssertEqual(page.date, DateFormatter.wmfMediumDateFormatter(languageCode: nil).string(from: yesterday))
    }

    func testPagesOfDifferentDaysHaveDifferentIDs() throws {
        let now = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: now))
        XCTAssertNotEqual(try page(date: now).id, try page(date: yesterday).id)
        XCTAssertNotEqual(try page(project: english).id, try page(project: arabic).id)
    }

    // MARK: - Language

    func testARightToLeftWikiLaysTheFeedOutRightToLeft() throws {
        XCTAssertTrue(try page(project: arabic).isRTL)
        XCTAssertFalse(try page(project: english).isRTL)
    }

    /// Like Android, the date above each day follows the app language, not the wiki's.
    func testTheDateHeaderFollowsTheAppLanguageInAnotherWiki() throws {
        let now = Date()
        let page = try page(date: now, project: arabic, now: now)
        XCTAssertEqual(page.date, "Today - \(DateFormatter.wmfMediumDateFormatter(languageCode: nil).string(from: now))")
    }

    // MARK: - Years ago

    func testYearsAgoNamesThisYearAndLastYear() {
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsAgo(0, languageCode: "en"), "This year")
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsAgo(1, languageCode: "en"), "Last year")
    }

    func testYearsAgoUsesTheAppsPluralString() {
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsAgo(6, languageCode: "en"), "6 years ago")
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsAgo(6, languageCode: nil), String(format: CommonStrings.yearsAgo(languageCode: nil), locale: .current, 6))
    }

    func testYearsAgoIsInTheWikiLanguage() {
        let arabic = WMFHomeCommunityViewModel.yearsAgo(6, languageCode: "ar")
        XCTAssertFalse(arabic.contains("years"), "Arabic: \(arabic)")
    }

    func testOnThisDayItemsSayYearsAgoInTheWikiLanguage() throws {
        let item = try XCTUnwrap(try page(project: arabic).onThisDayItems?.first)
        let years = Calendar.current.component(.year, from: Date()) - 2013
        XCTAssertEqual(item.yearsAgo, WMFHomeCommunityViewModel.yearsAgo(years, languageCode: "ar"))
    }

    func testFeedStringsUseTheWikiLanguage() throws {
        XCTAssertEqual(try page(project: arabic).strings.languageCode, "ar")
    }

    // MARK: - iPad columns

    func testEveryModuleHasAColumnAndBothColumnsAreUsed() {
        let leading = WMFCommunityModule.allCases.filter(\.isInLeadingColumn)
        let trailing = WMFCommunityModule.allCases.filter { !$0.isInLeadingColumn }
        XCTAssertEqual(leading, [.featuredArticle, .topRead, .pictureOfDay])
        XCTAssertEqual(trailing, [.inTheNews, .onThisDay])
    }
}
