import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFFeedDataControllerTests: XCTestCase {

    private let basicService = WMFMockBasicService(jsonResourceName: "feed-featured-2025-12-11-get")
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private var fixtureDate: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 11
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private func fetchFixture() async throws -> WMFFeedAPIResponse {
        try await WMFFeedDataController(basicService: basicService).fetchFeed(project: enProject, date: fixtureDate)
    }

    // MARK: - Fetch

    func testFetchFeedSucceeds() async throws {
        _ = try await fetchFixture()
    }

    // MARK: - Today's Featured Article

    func testParseTodaysFeaturedArticle() async throws {
        let tfa = try await fetchFixture().todaysFeaturedArticle
        XCTAssertNotNil(tfa, "TFA should not be nil")
        XCTAssertEqual(tfa?.title, "George_Mason")
        XCTAssertEqual(tfa?.normalizedTitle, "George Mason")
        XCTAssertEqual(tfa?.pageid, 224314)
        XCTAssertEqual(tfa?.lang, "en")
        XCTAssertEqual(tfa?.description, "American Founding Father and Bill of Rights advocate (1725–1792)")
        XCTAssertEqual(tfa?.descriptionSource, "local")
        XCTAssertEqual(tfa?.wikibaseItem, "Q532329")
        XCTAssertEqual(tfa?.namespace?.id, 0)
        XCTAssertEqual(tfa?.revision, "1357446716")
    }

    func testParseTFAThumbnail() async throws {
        let thumbnail = try await fetchFixture().todaysFeaturedArticle?.thumbnail
        XCTAssertEqual(thumbnail?.width, 772)
        XCTAssertEqual(thumbnail?.height, 900)
        XCTAssertEqual(thumbnail?.source, "https://upload.wikimedia.org/wikipedia/commons/1/12/George_Mason.jpg")
    }

    func testParseTFAContentURLs() async throws {
        let urls = try await fetchFixture().todaysFeaturedArticle?.contentURLs
        XCTAssertEqual(urls?.desktop?.page, "https://en.wikipedia.org/wiki/George_Mason")
        XCTAssertEqual(urls?.desktop?.edit, "https://en.wikipedia.org/wiki/George_Mason?action=edit")
        XCTAssertEqual(urls?.desktop?.talk, "https://en.wikipedia.org/wiki/Talk:George_Mason")
        XCTAssertEqual(urls?.mobile?.page, "https://en.wikipedia.org/wiki/George_Mason")
        XCTAssertEqual(urls?.mobile?.revisions, "https://en.wikipedia.org/wiki/Special:History/George_Mason")
    }

    func testParseTFATitles() async throws {
        let titles = try await fetchFixture().todaysFeaturedArticle?.titles
        XCTAssertEqual(titles?.canonical, "George_Mason")
        XCTAssertEqual(titles?.normalized, "George Mason")
    }

    // MARK: - Most Read

    func testParseMostRead() async throws {
        let mostRead = try await fetchFixture().mostRead
        XCTAssertNotNil(mostRead)
        XCTAssertEqual(mostRead?.date, "2025-12-10Z")
        XCTAssertEqual(mostRead?.articles?.count, 2)
    }

    func testParseMostReadFirstArticle() async throws {
        let first = try await fetchFixture().mostRead?.articles?.first
        XCTAssertEqual(first?.title, "Dhurandhar")
        XCTAssertEqual(first?.normalizedTitle, "Dhurandhar")
        XCTAssertEqual(first?.views, 562210)
        XCTAssertEqual(first?.rank, 3)
        XCTAssertEqual(first?.pageid, 80369939)
        XCTAssertEqual(first?.description, "2025 Indian film by Aditya Dhar")
        XCTAssertEqual(first?.wikibaseItem, "Q135230927")
    }

    func testParseMostReadViewHistory() async throws {
        let viewHistory = try await fetchFixture().mostRead?.articles?.first?.viewHistory
        XCTAssertEqual(viewHistory?.count, 5)
        XCTAssertEqual(viewHistory?.first?.date, "2025-12-06Z")
        XCTAssertEqual(viewHistory?.first?.views, 397072)
        XCTAssertEqual(viewHistory?.last?.views, 562210)
    }

    func testParseMostReadArticleWithNoThumbnail() async throws {
        let second = try await fetchFixture().mostRead?.articles?.dropFirst().first
        XCTAssertEqual(second?.title, "E-Government_in_Saudi_Arabia")
        XCTAssertNil(second?.thumbnail, "Second article should have no thumbnail")
    }

    // MARK: - Image of the Day

    func testParseImageOfTheDay() async throws {
        let image = try await fetchFixture().image
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.title, "File:Mountains_in_snow,_Mountain_lake,_Chola_Valley,_Nepal,_Himalayas.jpg")
        XCTAssertEqual(image?.image?.width, 4032)
        XCTAssertEqual(image?.image?.height, 2688)
        XCTAssertEqual(image?.thumbnail?.width, 640)
        XCTAssertEqual(image?.license?.code, "cc-by-4.0")
        XCTAssertEqual(image?.license?.type, "CC BY 4.0")
        XCTAssertEqual(image?.description?.lang, "en")
        XCTAssertEqual(image?.artist?.text, "Vyacheslav Argenberg")
        XCTAssertEqual(image?.wbEntityId, "M134682226")
        XCTAssertEqual(image?.structured?.captions?["en"], "Mountains in snow. Mountain lake. Chola Valley, Nepal, Himalayas.")
        XCTAssertEqual(image?.structured?.captions?["fr"], "Vallée du Chola, népal")
    }

    func testParseImageFilePage() async throws {
        let filePage = try await fetchFixture().image?.filePage
        XCTAssertEqual(filePage, "https://commons.wikimedia.org/wiki/File:Mountains_in_snow,_Mountain_lake,_Chola_Valley,_Nepal,_Himalayas.jpg")
    }

    // MARK: - News

    func testParseNews() async throws {
        let news = try await fetchFixture().news
        XCTAssertNotNil(news)
        XCTAssertEqual(news?.count, 4)
    }

    func testParseNewsFirstItemStory() async throws {
        let firstStory = try await fetchFixture().news?.first?.story
        XCTAssertNotNil(firstStory)
        XCTAssertTrue(firstStory?.contains("New York Knicks") == true)
        XCTAssertTrue(firstStory?.contains("NBA Finals") == true)
    }

    func testParseNewsFirstItemLinks() async throws {
        let links = try await fetchFixture().news?.first?.links
        XCTAssertEqual(links?.count, 5)
    }

    func testParseNewsFirstItemFirstLink() async throws {
        let link = try await fetchFixture().news?.first?.links?.first
        XCTAssertEqual(link?.title, "2026_NBA_Finals")
        XCTAssertEqual(link?.normalizedTitle, "2026 NBA Finals")
        XCTAssertEqual(link?.pageid, 82427430)
        XCTAssertEqual(link?.description, "North America basketball championship")
        XCTAssertEqual(link?.lang, "en")
    }

    func testParseNewsFirstItemFirstLinkThumbnail() async throws {
        let thumbnail = try await fetchFixture().news?.first?.links?.first?.thumbnail
        XCTAssertEqual(thumbnail?.width, 330)
        XCTAssertEqual(thumbnail?.height, 200)
        XCTAssertEqual(thumbnail?.source, "https://upload.wikimedia.org/wikipedia/en/thumb/f/ff/2026_NBA_Finals_Logo.png/330px-2026_NBA_Finals_Logo.png")
    }

    func testParseNewsFirstItemFirstLinkContentURLs() async throws {
        let contentURLs = try await fetchFixture().news?.first?.links?.first?.contentURLs
        XCTAssertEqual(contentURLs?.desktop?.page, "https://en.wikipedia.org/wiki/2026_NBA_Finals")
        XCTAssertEqual(contentURLs?.mobile?.page, "https://en.wikipedia.org/wiki/2026_NBA_Finals")
        XCTAssertEqual(contentURLs?.mobile?.revisions, "https://en.wikipedia.org/wiki/Special:History/2026_NBA_Finals")
    }

    func testParseNewsLastItemStoryAndLink() async throws {
        let lastItem = try await fetchFixture().news?.last
        XCTAssertTrue(lastItem?.story?.contains("David Hockney") == true)
        XCTAssertEqual(lastItem?.links?.count, 1)
        XCTAssertEqual(lastItem?.links?.first?.title, "David_Hockney")
        XCTAssertEqual(lastItem?.links?.first?.pageid, 238341)
    }

    // MARK: - onthisday excluded

    func testOnThisDayIsNotDeserialized() async throws {
        // WMFFeedAPIResponse intentionally omits onthisday (T418486).
        // Verify that omitting it doesn't break decoding of everything else.
        let response = try await fetchFixture()
        XCTAssertNotNil(response.todaysFeaturedArticle, "TFA must decode even when onthisday is present in JSON")
        XCTAssertNotNil(response.mostRead, "mostRead must decode even when onthisday is present in JSON")
        XCTAssertNotNil(response.image, "image must decode even when onthisday is present in JSON")
    }
}
