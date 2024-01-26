import XCTest

@testable import WKData
@testable import WKDataMocks

final class WKGrowthTasksDataControllerTests: XCTestCase {

    private let csProject = WKProject.wikipedia(WKLanguage(languageCode: "cs", languageVariantCode: nil))

    override func setUp() async throws {
        WKDataEnvironment.current.mediaWikiService = WKMockGrowthTasksService()
    }

    func testFetchGrowthTasks() {
        let controller = WKGrowthTasksDataController(project: csProject)
        let expectation = XCTestExpectation(description: "Fetch Growth Tasks")

        var tasksToTest: [WKGrowthTask.Page]?
        controller.getGrowthAPITask { result in
            switch result {
            case .success(let response):
                tasksToTest = response
            case .failure(let error):
                XCTFail("Failure fetching tasks: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        XCTAssertTrue(tasksToTest != nil)
    }

    func testParsingTasks() {

        let controller = WKGrowthTasksDataController(project: csProject)
        var tasksToTest: [WKGrowthTask.Page]?
        controller.getGrowthAPITask { result in
            switch result {
            case .success(let response):
                tasksToTest = response
            case .failure(let error):
                XCTFail("Failure fetching tasks: \(error)")
            }
        }

        guard let tasksToTest else {
            XCTFail("Failed to retrive Growth Tasks")
            return
        }

        XCTAssertEqual(tasksToTest.count, 10, "Incorrect number of tasks")

        let firstTask = tasksToTest.first!

        XCTAssertEqual(firstTask.pageid, 35571, "Incorrect page ID")
        XCTAssertEqual(firstTask.title, "Novela (právo)", "Incorrect title")

    }

}
