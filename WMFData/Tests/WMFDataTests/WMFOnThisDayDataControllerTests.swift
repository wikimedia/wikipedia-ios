import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFOnThisDayDataControllerTests: XCTestCase {

    private func makeController(mockJSONResource: String) throws -> WMFOnThisDayDataController {
        let mockService = WMFMockBasicService(jsonResourceName: mockJSONResource)
        return WMFOnThisDayDataController(basicService: mockService)
    }

    // MARK: - fetchOnThisDay – happy path

    func testFetchOnThisDayParsesEventsCount() async throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        
        let response = try await controller.fetchOnThisDay(project: .wikipedia(.init(languageCode: "en", languageVariantCode: nil)), month: 2, day: 21)
        XCTAssertEqual(response.events.count, 3)
        XCTAssertEqual(response.events[0].text, "Wikipedia, a free wiki content encyclopedia, goes online.")
        XCTAssertEqual(response.events[0].year, 2001)
        XCTAssertEqual(response.events[0].pages.first?.title, "Wikipedia")
        XCTAssertEqual(response.events[0].pages.first?.description, "Free online encyclopedia that anyone can edit")
        let expectedURL = URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/8/80/Wikipedia-logo-v2.svg/320px-Wikipedia-logo-v2.svg.png")
        XCTAssertEqual(response.events[0].pages.first?.thumbnail?.source, expectedURL)
        let thumbnail = response.events[0].pages.first?.thumbnail
        XCTAssertEqual(thumbnail?.width, 320)
        XCTAssertEqual(thumbnail?.height, 320)
        let expectedURL2 = URL(string: "https://en.wikipedia.org/wiki/Wikipedia")
        XCTAssertEqual(response.events[0].pages.first?.contentUrls?.desktop?.page, expectedURL2)
        let expectedURL3 = URL(string: "https://en.m.wikipedia.org/wiki/Wikipedia")
        XCTAssertEqual(response.events[0].pages.first?.contentUrls?.mobile?.page, expectedURL3)
        XCTAssertNil(response.events[2].pages.first?.thumbnail)
        let secondEvent = response.events[1]
        XCTAssertEqual(secondEvent.year, 1844)
        XCTAssertEqual(secondEvent.text, "The Dominican Republic gains independence from Haiti.")
        XCTAssertEqual(secondEvent.pages.first?.title, "Dominican Republic")
    }
    
    func testFetchOnThisDayThrowsForWikidata() async throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        do {
            _ = try await controller.fetchOnThisDay(project: .wikidata, month: 2, day: 21)
            XCTFail("Expected unsupportedProject error, got success")
        } catch let error as WMFDataControllerError {
            XCTAssertEqual(error, .unsupportedProject)
        }
    }

    func testFetchOnThisDayThrowsForCommons() async throws {
        let controller = try makeController(mockJSONResource: "onthisday-events-02-21-get")
        do {
            _ = try await controller.fetchOnThisDay(project: .commons, month: 2, day: 21)
            XCTFail("Expected unsupportedProject error, got success")
        } catch let error as WMFDataControllerError {
            XCTAssertEqual(error, .unsupportedProject)
        }
    }
}
