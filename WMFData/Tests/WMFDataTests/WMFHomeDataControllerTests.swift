import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFHomeDataControllerTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private var dec11: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 11
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private var dec10: Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 12
        components.day = 10
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private let stubResponse = WMFFeedAPIResponse(todaysFeaturedArticle: nil, mostRead: nil, image: nil, news: nil)

    private func makeController() -> (WMFHomeDataController, WMFMockFeedDataController) {
        let spy = WMFMockFeedDataController(response: stubResponse)
        let controller = WMFHomeDataController(feedDataController: spy)
        return (controller, spy)
    }

    // MARK: - fetchCommunity

    func testFetchCommunitySucceeds() async throws {
        let (controller, _) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
    }

    func testFetchCommunityRequestsCorrectDate() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        let calls = await spy.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(calls[0].date, inSameDayAs: dec11))
    }

    func testFetchCommunityDeduplicatesSameDay() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        _ = try await controller.fetchCommunity(project: enProject, date: dec10)
        _ = try await controller.fetchCommunity(project: enProject, date: dec10) // duplicate — should not be recorded
        // fetchedDates should be [Dec 11, Dec 10]; previousPage anchors off Dec 10 → Dec 9.
        _ = try await controller.fetchPreviousPage(project: enProject)
        let calls = await spy.calls
        let calendar = Calendar(identifier: .gregorian)
        var dec9Components = DateComponents()
        dec9Components.year = 2025
        dec9Components.month = 12
        dec9Components.day = 9
        let dec9 = calendar.date(from: dec9Components)!
        XCTAssertEqual(calls.count, 4)
        XCTAssertTrue(calendar.isDate(calls[3].date, inSameDayAs: dec9))
    }

    func testFetchCommunityFailsForNonWikipediaProject() async throws {
        let controller = WMFHomeDataController(feedDataController: WMFFeedDataController())
        do {
            _ = try await controller.fetchCommunity(project: .commons, date: dec11)
            XCTFail("Expected unsupportedProject error")
        } catch WMFDataControllerError.unsupportedProject {
            // expected
        }
    }

    // MARK: - fetchPreviousPage

    func testFetchPreviousPageThrowsWithoutInitialFetch() async throws {
        let (controller, _) = makeController()
        do {
            _ = try await controller.fetchPreviousPage(project: enProject)
            XCTFail("Expected noFetchedDatesAvailable error")
        } catch WMFHomeDataControllerError.noFetchedDatesAvailable {
            // expected
        }
    }

    func testFetchPreviousPageIsIsolatedByProject() async throws {
        let esProject = WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil))
        let (controller, _) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        // Fetching en on Dec 11 should not seed the es project's date history.
        do {
            _ = try await controller.fetchPreviousPage(project: esProject)
            XCTFail("Expected noFetchedDatesAvailable error")
        } catch WMFHomeDataControllerError.noFetchedDatesAvailable {
            // expected
        }
    }

    func testFetchPreviousPageRequestsPreviousDate() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunity(project: enProject, date: dec11)
        _ = try await controller.fetchPreviousPage(project: enProject)
        let calls = await spy.calls
        XCTAssertEqual(calls.count, 2)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(calls[1].date, inSameDayAs: dec10))
    }
}
