import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFNativeLocalizations

@MainActor
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

    func testANewsStoryKeepsItsLinkedArticles() throws {
        let page = try page(feedJSON: #"{ "news": [ { "story": "A story", "links": [ { "title": "Black_hole" } ] } ] }"#)
        XCTAssertEqual(page.newsItems.first?.newsItem.links?.first?.title, "Black_hole")
    }

    /// Two stories with the same text, or with no text, must not share a SwiftUI ID.
    func testNewsStoriesWithTheSameTextHaveDifferentIDs() throws {
        let page = try page(feedJSON: #"{ "news": [ { "story": "Same" }, { "story": "Same" }, { }, { } ] }"#)
        XCTAssertEqual(Set(page.newsItems.map(\.id)).count, 4)
    }

    func testANewsStoryKeepsItsIDAcrossARefreshOfTheSameDay() throws {
        let json = #"{ "news": [ { "story": "A story" }, { "story": "Another story" } ] }"#
        XCTAssertEqual(try page(feedJSON: json).newsItems.map(\.id), try page(feedJSON: json).newsItems.map(\.id))
    }

    /// An event that lists a page twice gets one row for it, because the rows use the title as ID.
    func testAnOnThisDayEventListsEachPageOnce() throws {
        let feedJSON = #"{ "onthisday": [ { "text": "Picked", "year": 1945, "pages": [ { "title": "Dog" }, { "title": "Cat" }, { "title": "Dog" } ] } ] }"#
        let item = try XCTUnwrap(try page(feedJSON: feedJSON).onThisDayItems?.first)
        XCTAssertEqual(item.pages.map(\.title), ["Dog", "Cat"])
    }

    // MARK: - Event years

    /// The feed gives 44 BC as -44 and has no year 0.
    func testAYearBeforeYearOneShowsItsEra() {
        XCTAssertEqual(DateFormatter.wmfEventYearString(-44, languageCode: "en"), "44 BC")
        XCTAssertEqual(DateFormatter.wmfEventYearString(-1, languageCode: "en"), "1 BC")
    }

    func testAYearAfterYearOneShowsTheYearAlone() {
        XCTAssertEqual(DateFormatter.wmfEventYearString(1984, languageCode: "en"), "1984")
        XCTAssertEqual(DateFormatter.wmfEventYearString(1, languageCode: "en"), "1")
    }

    func testEventYearsCountNoYearZero() {
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsBetween(1984, and: 2026), 42)
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsBetween(-44, and: 2026), 2069)
        XCTAssertEqual(WMFHomeCommunityViewModel.yearsBetween(-1, and: 1), 1)
    }

    func testAnOnThisDayEventBeforeYearOneShowsItsEraAndYearsAgo() throws {
        let feedJSON = #"{ "onthisday": [ { "text": "Caesar", "year": -44, "pages": [] } ] }"#
        let now = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 12)))
        let item = try XCTUnwrap(try page(feedJSON: feedJSON, date: now, now: now).onThisDayItems?.first)
        XCTAssertEqual(item.yearText, "44 BC")
        XCTAssertEqual(item.yearsAgo, WMFHomeCommunityViewModel.yearsAgo(2069, languageCode: "en"))
    }

    func testOnThisDayWithNoEventsHasNoItems() throws {
        XCTAssertNil(try page(onThisDayEvents: 0).onThisDayItems)
    }

    // MARK: - Date header

    func testTodaysPageSaysToday() throws {
        let now = Date()
        let page = try page(date: now, now: now)
        let formatted = DateFormatter.wmfShortMonthDayYearDateFormatter.string(from: now)
        // Built from the app's own string, so the test passes in any simulator language.
        XCTAssertEqual(page.date, WMFCommunityFeedStrings.todayDateHeader(formatted))
        XCTAssertNotEqual(page.date, formatted, "Today's header says today, not only the date")
    }

    func testAnEarlierPageShowsOnlyItsDate() throws {
        let now = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: now))
        let page = try page(date: yesterday, now: now)
        XCTAssertEqual(page.date, DateFormatter.wmfShortMonthDayYearDateFormatter.string(from: yesterday))
    }

    func testPagesOfDifferentDaysHaveDifferentIDs() throws {
        let now = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: now))
        XCTAssertNotEqual(try page(date: now).id, try page(date: yesterday).id)
        XCTAssertNotEqual(try page(project: english).id, try page(project: arabic).id)
    }

    // MARK: - Language

    /// Like Android, the date above each day follows the app language, not the wiki's.
    func testTheDateHeaderFollowsTheAppLanguageInAnotherWiki() throws {
        let now = Date()
        let page = try page(date: now, project: arabic, now: now)
        XCTAssertEqual(page.date, WMFCommunityFeedStrings.todayDateHeader(DateFormatter.wmfShortMonthDayYearDateFormatter.string(from: now)))
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

    /// The Figma puts the image-led modules on the leading side and the story modules on the other.
    func testColumnsFollowTheFigma() {
        let columns = WMFHomeCommunityViewModel.columns(for: WMFCommunityModule.allCases)
        XCTAssertEqual(columns.leading, [.featuredArticle, .topRead, .pictureOfDay])
        XCTAssertEqual(columns.trailing, [.inTheNews, .onThisDay])
    }

    func testOneModuleTakesTheLeadingColumnAlone() {
        let columns = WMFHomeCommunityViewModel.columns(for: [.inTheNews])
        XCTAssertEqual(columns.leading, [.inTheNews])
        XCTAssertTrue(columns.trailing.isEmpty)
    }

    /// Small wikis such as Scots or Simple English have only Top read and Picture of the day, both
    /// image-led. They share the two columns instead of leaving the trailing one blank.
    func testImageModulesAloneShareBothColumns() {
        let columns = WMFHomeCommunityViewModel.columns(for: [.topRead, .pictureOfDay])
        XCTAssertEqual(columns.leading, [.topRead])
        XCTAssertEqual(columns.trailing, [.pictureOfDay])
    }

    func testStoryModulesAloneShareBothColumns() {
        let columns = WMFHomeCommunityViewModel.columns(for: [.inTheNews, .onThisDay])
        XCTAssertEqual(columns.leading, [.inTheNews])
        XCTAssertEqual(columns.trailing, [.onThisDay])
    }

    func testThreeImageModulesSplitTwoAndOne() {
        let columns = WMFHomeCommunityViewModel.columns(for: [.featuredArticle, .topRead, .pictureOfDay])
        XCTAssertEqual(columns.leading, [.featuredArticle, .topRead])
        XCTAssertEqual(columns.trailing, [.pictureOfDay])
    }

    /// English on most days: no In the news. Three image modules against one story would leave a
    /// tall gap, so the last image module moves across.
    func testUnevenSidesAreBalanced() {
        let columns = WMFHomeCommunityViewModel.columns(for: [.featuredArticle, .topRead, .onThisDay, .pictureOfDay])
        XCTAssertEqual(columns.leading, [.featuredArticle, .topRead])
        XCTAssertEqual(columns.trailing, [.onThisDay, .pictureOfDay])
    }

    /// Arabic and Portuguese often have no Featured article and no In the news.
    func testOneModuleOnEachSideKeepsTheFigmaSides() {
        let columns = WMFHomeCommunityViewModel.columns(for: [.topRead, .onThisDay, .pictureOfDay])
        XCTAssertEqual(columns.leading, [.topRead, .pictureOfDay])
        XCTAssertEqual(columns.trailing, [.onThisDay])
    }

    func testEveryModuleAppearsOnceForAnyMix() {
        let all = WMFCommunityModule.allCases
        for mask in 1..<(1 << all.count) {
            let modules = all.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element)
            let columns = WMFHomeCommunityViewModel.columns(for: modules)
            XCTAssertEqual(Set(columns.leading + columns.trailing), Set(modules))
            XCTAssertEqual(columns.leading.count + columns.trailing.count, modules.count)
            XCTAssertFalse(columns.leading.isEmpty)
            XCTAssertLessThanOrEqual(abs(columns.leading.count - columns.trailing.count), 1, "\(modules)")
        }
    }

    // MARK: - On this day events

    /// Like Android, the module shows the events the wiki's editors picked, not the newest ones.
    func testOnThisDayPrefersTheEditorsPicks() throws {
        let feedJSON = #"{ "onthisday": [ { "text": "Picked", "year": 1945, "pages": [] }, { "text": "Also picked", "year": 1943, "pages": [] }, { "text": "Third pick", "year": 1900, "pages": [] } ] }"#
        let items = try XCTUnwrap(try page(feedJSON: feedJSON, onThisDayEvents: 3).onThisDayItems)
        XCTAssertEqual(items.map(\.year), [1945, 1943])
        XCTAssertEqual(items.map(\.text), ["Picked", "Also picked"])
    }

    func testOnThisDayFallsBackToTheFullListWithoutPicks() throws {
        let items = try XCTUnwrap(try page(feedJSON: #"{ }"#, onThisDayEvents: 3).onThisDayItems)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first?.year, 2013)
    }

    private let fullList = [
        WMFOnThisDayEvent(text: "Newest", year: 2022, pages: []),
        WMFOnThisDayEvent(text: "The Angolan government and UNITA rebels sign the Lusaka Protocol", year: 1994, pages: []),
        WMFOnThisDayEvent(text: "Another 1994 event", year: 1994, pages: []),
        WMFOnThisDayEvent(text: "Same words as the card", year: 1945, pages: [])
    ]

    func testATappedEventOpensAtTheEventWithTheSameText() {
        XCTAssertEqual(WMFHomeCommunityViewModel.onThisDayEventIndex(year: 1945, text: "Same words as the card", in: fullList), 3)
        XCTAssertEqual(WMFHomeCommunityViewModel.onThisDayEventIndex(year: 1994, text: "Another 1994 event", in: fullList), 2)
    }

    /// The editors' picks word an event differently from the full list.
    func testATappedPickOpensAtTheFirstEventOfItsYear() {
        let index = WMFHomeCommunityViewModel.onThisDayEventIndex(year: 1994, text: "In accordance with the Lusaka Protocol, the Angolan government signed a ceasefire", in: fullList)
        XCTAssertEqual(index, 1)
    }

    func testATappedEventWithoutItsYearInTheListHasNoPosition() {
        XCTAssertNil(WMFHomeCommunityViewModel.onThisDayEventIndex(year: 1066, text: "Not listed", in: fullList))
    }

    // MARK: - Articles

    func testRowsKeepTheItalicsOfTheDisplayTitle() throws {
        let feedJSON = #"{ "mostread": { "articles": [ { "title": "Grand_Theft_Auto_VI", "displaytitle": "<i>Grand Theft Auto VI</i>", "description": "2026 video game", "thumbnail": { "source": "https://upload.wikimedia.org/gta.jpg" } } ] } }"#
        let item = try XCTUnwrap(try page(feedJSON: feedJSON).topReadItems.first)
        XCTAssertEqual(item.title, "Grand_Theft_Auto_VI")
        XCTAssertEqual(item.displayTitleHTML, "<i>Grand Theft Auto VI</i>")
        XCTAssertEqual(item.plainTitle, "Grand Theft Auto VI")
        XCTAssertEqual(item.description, "2026 video game")
        XCTAssertEqual(item.thumbnailURL?.absoluteString, "https://upload.wikimedia.org/gta.jpg")
    }

    /// The module shows five rows; "More top read" opens every article of the day.
    func testTopReadShowsFiveButKeepsTheFullList() throws {
        let articles = (1...8).map { #"{ "title": "Article_\#($0)" }"# }.joined(separator: ",")
        let page = try page(feedJSON: #"{ "mostread": { "articles": [\#(articles)] } }"#)
        XCTAssertEqual(page.topReadItems.count, 5)
        XCTAssertEqual(page.allTopReadTitles.count, 8)
        XCTAssertEqual(page.allTopReadTitles.last, "Article_8")
    }

    func testTopReadSaysTodayOnlyOnTodaysPage() throws {
        let now = Date()
        let yesterday = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -1, to: now))
        XCTAssertEqual(try page(date: now, now: now).subtitle(for: .topRead), WMFCommunityModule.topRead.subtitle(languageCode: "en"))
        let earlier = try page(date: yesterday, now: now)
        XCTAssertEqual(earlier.subtitle(for: .topRead), earlier.strings.topReadPastSubtitle)
        XCTAssertNotEqual(earlier.subtitle(for: .topRead), WMFCommunityModule.topRead.subtitle(languageCode: "en"))
    }

    func testPictureOfTheDayHasItsDescriptionAsCaption() throws {
        let feedJSON = #"{ "image": { "title": "File:Sky.jpg", "thumbnail": { "source": "https://upload.wikimedia.org/sky.jpg" }, "description": { "html": "Trail from <b>Andiast</b>", "text": "Trail from Andiast" } } }"#
        XCTAssertEqual(try page(feedJSON: feedJSON).pictureOfDayCaption, "Trail from Andiast")
        XCTAssertNil(try page().pictureOfDayCaption)
    }
}
