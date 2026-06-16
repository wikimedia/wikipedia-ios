import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFExploreDataControllerTests: XCTestCase {

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

    private func makeController() -> (WMFExploreDataController, WMFMockFeedDataController) {
        let spy = WMFMockFeedDataController(response: stubResponse)
        let controller = WMFExploreDataController(feedDataController: spy)
        return (controller, spy)
    }

    // MARK: - fetchCommunityPicks

    func testFetchCommunityPicksSucceeds() async throws {
        let (controller, _) = makeController()
        _ = try await controller.fetchCommunityPicks(project: enProject, date: dec11)
    }

    func testFetchCommunityPicksRequestsCorrectDate() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunityPicks(project: enProject, date: dec11)
        let calls = await spy.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(calls[0].date, inSameDayAs: dec11))
    }

    func testFetchCommunityPicksDeduplicatesSameDay() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunityPicks(project: enProject, date: dec11)
        _ = try await controller.fetchCommunityPicks(project: enProject, date: dec10)
        _ = try await controller.fetchCommunityPicks(project: enProject, date: dec10) // duplicate — should not be recorded
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

    func testFetchCommunityPicksFailsForNonWikipediaProject() async throws {
        let controller = WMFExploreDataController(feedDataController: WMFFeedDataController())
        do {
            _ = try await controller.fetchCommunityPicks(project: .commons, date: dec11)
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
        } catch WMFExploreDataControllerError.noFetchedDatesAvailable {
            // expected
        }
    }

    func testFetchPreviousPageRequestsPreviousDate() async throws {
        let (controller, spy) = makeController()
        _ = try await controller.fetchCommunityPicks(project: enProject, date: dec11)
        _ = try await controller.fetchPreviousPage(project: enProject)
        let calls = await spy.calls
        XCTAssertEqual(calls.count, 2)
        XCTAssertTrue(Calendar(identifier: .gregorian).isDate(calls[1].date, inSameDayAs: dec10))
    }

}
