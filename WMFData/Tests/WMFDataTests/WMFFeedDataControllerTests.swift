import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFFeedDataControllerTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    // December 11, 2025 — matches the fixture filename
    private var fixtureDate: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 11
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    override func setUp() {
        super.setUp()
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "feed-featured-2025-12-11-get")
    }

    // MARK: - Fetch

    func testFetchFeedSucceeds() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Fetch feed")

        var fetchedResponse: WMFFeedAPIResponse?

        controller.fetchFeed(project: enProject, date: fixtureDate) { result in
            switch result {
            case .success(let response):
                fetchedResponse = response
            case .failure(let error):
                XCTFail("Failed to fetch feed: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertNotNil(fetchedResponse)
    }

    // MARK: - Today's Featured Article

    func testParseTodaysFeaturedArticle() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse TFA")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let tfa = response?.todaysFeaturedArticle
        XCTAssertNotNil(tfa, "TFA should not be nil")
        XCTAssertEqual(tfa?.title, "George_Mason", "Incorrect TFA title")
        XCTAssertEqual(tfa?.normalizedTitle, "George Mason", "Incorrect TFA normalizedtitle")
        XCTAssertEqual(tfa?.pageid, 224314, "Incorrect TFA page ID")
        XCTAssertEqual(tfa?.lang, "en", "Incorrect TFA language")
        XCTAssertEqual(tfa?.description, "American Founding Father and Bill of Rights advocate (1725–1792)", "Incorrect TFA description")
        XCTAssertEqual(tfa?.descriptionSource, "local", "Incorrect description_source")
        XCTAssertEqual(tfa?.wikibaseItem, "Q532329", "Incorrect wikibase item")
        XCTAssertEqual(tfa?.namespace?.id, 0, "Incorrect namespace ID")
        XCTAssertEqual(tfa?.revision, "1357446716", "Incorrect revision")
    }

    func testParseTFAThumbnail() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse TFA thumbnail")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let thumbnail = response?.todaysFeaturedArticle?.thumbnail
        XCTAssertEqual(thumbnail?.width, 772, "Incorrect thumbnail width")
        XCTAssertEqual(thumbnail?.height, 900, "Incorrect thumbnail height")
        XCTAssertEqual(thumbnail?.source, "https://upload.wikimedia.org/wikipedia/commons/1/12/George_Mason.jpg", "Incorrect thumbnail source")
    }

    func testParseTFAContentURLs() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse TFA content URLs")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let urls = response?.todaysFeaturedArticle?.contentURLs
        XCTAssertEqual(urls?.desktopPage, "https://en.wikipedia.org/wiki/George_Mason", "Incorrect desktop page URL")
        XCTAssertEqual(urls?.desktopEdit, "https://en.wikipedia.org/wiki/George_Mason?action=edit", "Incorrect desktop edit URL")
        XCTAssertEqual(urls?.desktopTalk, "https://en.wikipedia.org/wiki/Talk:George_Mason", "Incorrect desktop talk URL")
        XCTAssertEqual(urls?.mobilePage, "https://en.wikipedia.org/wiki/George_Mason", "Incorrect mobile page URL")
        XCTAssertEqual(urls?.mobileRevisions, "https://en.wikipedia.org/wiki/Special:History/George_Mason", "Incorrect mobile revisions URL")
    }

    func testParseTFATitles() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse TFA titles")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let titles = response?.todaysFeaturedArticle?.titles
        XCTAssertEqual(titles?.canonical, "George_Mason", "Incorrect canonical title")
        XCTAssertEqual(titles?.normalized, "George Mason", "Incorrect normalized title")
    }

    // MARK: - Most Read

    func testParseMostRead() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse most read")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let mostRead = response?.mostRead
        XCTAssertNotNil(mostRead, "mostRead should not be nil")
        XCTAssertEqual(mostRead?.date, "2025-12-10Z", "Incorrect most-read date")
        XCTAssertEqual(mostRead?.articles?.count, 2, "Incorrect article count")
    }

    func testParseMostReadFirstArticle() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse most read first article")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let first = response?.mostRead?.articles?.first
        XCTAssertEqual(first?.title, "Dhurandhar", "Incorrect first article title")
        XCTAssertEqual(first?.normalizedTitle, "Dhurandhar", "Incorrect normalizedtitle")
        XCTAssertEqual(first?.views, 562210, "Incorrect view count")
        XCTAssertEqual(first?.rank, 3, "Incorrect rank")
        XCTAssertEqual(first?.pageid, 80369939, "Incorrect page ID")
        XCTAssertEqual(first?.description, "2025 Indian film by Aditya Dhar", "Incorrect description")
        XCTAssertEqual(first?.wikibaseItem, "Q135230927", "Incorrect wikibase item")
    }

    func testParseMostReadViewHistory() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse view history")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let viewHistory = response?.mostRead?.articles?.first?.viewHistory
        XCTAssertEqual(viewHistory?.count, 5, "Incorrect view_history count")
        XCTAssertEqual(viewHistory?.first?.date, "2025-12-06Z", "Incorrect first history date")
        XCTAssertEqual(viewHistory?.first?.views, 397072, "Incorrect first history views")
        XCTAssertEqual(viewHistory?.last?.views, 562210, "Incorrect last history views")
    }

    func testParseMostReadArticleWithNoThumbnail() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse article without thumbnail")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        // Second article (E-Government in Saudi Arabia) has no thumbnail in the fixture
        let second = response?.mostRead?.articles?.dropFirst().first
        XCTAssertEqual(second?.title, "E-Government_in_Saudi_Arabia", "Incorrect second article title")
        XCTAssertNil(second?.thumbnail, "Second article should have no thumbnail")
    }

    // MARK: - Image of the Day

    func testParseImageOfTheDay() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse image of the day")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        let image = response?.image
        XCTAssertNotNil(image, "Image of the day should not be nil")
        XCTAssertEqual(image?.title, "File:Mountains_in_snow,_Mountain_lake,_Chola_Valley,_Nepal,_Himalayas.jpg", "Incorrect image title")
        XCTAssertEqual(image?.image?.width, 4032, "Incorrect full image width")
        XCTAssertEqual(image?.image?.height, 2688, "Incorrect full image height")
        XCTAssertEqual(image?.thumbnail?.width, 640, "Incorrect thumbnail width")
        XCTAssertEqual(image?.license?.code, "cc-by-4.0", "Incorrect license code")
        XCTAssertEqual(image?.license?.type, "CC BY 4.0", "Incorrect license type")
        XCTAssertEqual(image?.description?.lang, "en", "Incorrect description lang")
        XCTAssertEqual(image?.artist?.text, "Vyacheslav Argenberg", "Incorrect artist name")
        XCTAssertEqual(image?.wbEntityId, "M134682226", "Incorrect wb_entity_id")
        XCTAssertEqual(image?.structured?.captions?["en"], "Mountains in snow. Mountain lake. Chola Valley, Nepal, Himalayas.", "Incorrect EN caption")
        XCTAssertEqual(image?.structured?.captions?["fr"], "Vallée du Chola, népal", "Incorrect FR caption")
    }

    func testParseImageFilePage() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "Parse image file page")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(
            response?.image?.filePage,
            "https://commons.wikimedia.org/wiki/File:Mountains_in_snow,_Mountain_lake,_Chola_Valley,_Nepal,_Himalayas.jpg",
            "Incorrect file_page URL"
        )
    }

    // MARK: - onthisday excluded

    func testOnThisDayIsNotDeserialized() {
        let controller = WMFFeedDataController()
        let expectation = XCTestExpectation(description: "onthisday excluded")
        var response: WMFFeedAPIResponse?
        controller.fetchFeed(project: enProject, date: fixtureDate) { if case .success(let r) = $0 { response = r }; expectation.fulfill() }
        wait(for: [expectation], timeout: 10.0)

        // WMFFeedAPIResponse intentionally omits onthisday (T418486).
        // Verify that omitting it doesn't break decoding of everything else.
        XCTAssertNotNil(response?.todaysFeaturedArticle, "TFA must decode even when onthisday is present in JSON")
        XCTAssertNotNil(response?.mostRead, "mostRead must decode even when onthisday is present in JSON")
        XCTAssertNotNil(response?.image, "image must decode even when onthisday is present in JSON")
    }
}
