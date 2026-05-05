import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFOnThisDayDataControllerTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a controller backed by a mock service that returns the given JSON resource.
    private func makeController(mockJSONResource: String) throws -> WMFOnThisDayDataController {
        let mockService = WMFMockBasicService(jsonResourceName: mockJSONResource)
        return WMFOnThisDayDataController(basicService: mockService)
    }

    // MARK: - fetchOnThisDay – happy path

    func testFetchOnThisDayParsesEventsCount() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.events.count, 3)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventText() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(
                    response.events[0].text,
                    "Wikipedia, a free wiki content encyclopedia, goes online."
                )
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventYear() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.events[0].year, 2001)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventPageTitle() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.events[0].pages.first?.title, "Wikipedia")
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventPageDescription() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(
                    response.events[0].pages.first?.description,
                    "Free online encyclopedia that anyone can edit"
                )
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventThumbnailURL() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                let expectedURL = URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/320px-Wikipedia-logo-v2.svg.png")
                XCTAssertEqual(response.events[0].pages.first?.thumbnail?.source, expectedURL)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventThumbnailDimensions() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                let thumbnail = response.events[0].pages.first?.thumbnail
                XCTAssertEqual(thumbnail?.width, 320)
                XCTAssertEqual(thumbnail?.height, 320)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventDesktopURL() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                let expectedURL = URL(string: "https://en.wikipedia.org/wiki/Wikipedia")
                XCTAssertEqual(response.events[0].pages.first?.contentUrls?.desktop?.page, expectedURL)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesFirstEventMobileURL() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                let expectedURL = URL(string: "https://en.m.wikipedia.org/wiki/Wikipedia")
                XCTAssertEqual(response.events[0].pages.first?.contentUrls?.mobile?.page, expectedURL)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    /// Verifies that a null `thumbnail` in the JSON is decoded as `nil` (not a crash).
    func testFetchOnThisDayHandlesNullThumbnail() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                // The third event (Battle of Verdun) has a null thumbnail in the mock JSON.
                XCTAssertNil(response.events[2].pages.first?.thumbnail)
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayParsesSecondEventCorrectly() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en")), month: 2, day: 21) { result in
            switch result {
            case .success(let response):
                let secondEvent = response.events[1]
                XCTAssertEqual(secondEvent.year, 1844)
                XCTAssertEqual(secondEvent.text, "The Dominican Republic gains independence from Haiti.")
                XCTAssertEqual(secondEvent.pages.first?.title, "Dominican Republic")
            case .failure(let error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    // MARK: - fetchOnThisDay – unsupported project errors

    func testFetchOnThisDayThrowsForUnsupportedWikipediaLanguage() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        // "xx" is not a real / supported Wikipedia language code.
        controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "xx")), month: 2, day: 21) { result in
            switch result {
            case .success:
                XCTFail("Expected unsupportedProject error, got success")
            case .failure(let error):
                XCTAssertEqual(error as? WMFOnThisDayDataControllerError, .unsupportedProject)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayThrowsForWikidata() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .wikidata, month: 2, day: 21) { result in
            switch result {
            case .success:
                XCTFail("Expected unsupportedProject error, got success")
            case .failure(let error):
                XCTAssertEqual(error as? WMFOnThisDayDataControllerError, .unsupportedProject)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }

    func testFetchOnThisDayThrowsForCommons() throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        let expectation = expectation(description: "fetchOnThisDay completes")

        controller.fetchOnThisDay(project: .commons, month: 2, day: 21) { result in
            switch result {
            case .success:
                XCTFail("Expected unsupportedProject error, got success")
            case .failure(let error):
                XCTAssertEqual(error as? WMFOnThisDayDataControllerError, .unsupportedProject)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
    }
}
