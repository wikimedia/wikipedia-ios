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
            XCTFail("Failed to retrieve Growth Tasks")
            return
        }

        XCTAssertEqual(tasksToTest.count, 10, "Incorrect number of tasks")

        let firstTask = tasksToTest.first!

        XCTAssertEqual(firstTask.pageid, 35571, "Incorrect page ID")
        XCTAssertEqual(firstTask.title, "Novela (právo)", "Incorrect title")

    }

    func testFetchImageRecommendationForTasks() {

        let controller = WKGrowthTasksDataController(project: csProject)
        let expectation = XCTestExpectation(description: "Fetch Image Recommendations")

        var imageRecsToTest: [WKImageRecommendation.Page]?

        controller.getImageSuggestionData(pageIDs: ["1"]) { result in
            switch result {
            case .success(let response):
                imageRecsToTest = response
            case .failure(let error):
                XCTFail("Failed to fetch Image Recommendations \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        XCTAssertTrue(imageRecsToTest != nil)
    }

    func testParseImageReCommendations() {

        let controller = WKGrowthTasksDataController(project: csProject)
        var imageRecsToTest: [WKImageRecommendation.Page]?

        controller.getImageSuggestionData(pageIDs: ["1"]) { result in
            switch result {
            case .success(let response):
                imageRecsToTest = response
            case .failure(let error):
                XCTFail("Failed to fetch Image Recommendations \(error)")
            }
        }

        guard let imageRecsToTest else {
            XCTFail("Failed to retrieve image recommendations")
            return
        }

        let firstImageRecommendation = imageRecsToTest.first
        XCTAssertEqual(firstImageRecommendation?.pageid, 206400, "Incorrect page Id")
        XCTAssertEqual(firstImageRecommendation?.title, "Dialer", "Incorrect page title")
        XCTAssertEqual(firstImageRecommendation?.growthimagesuggestiondata.count, 1, "Incorrect growth suggestion data count")


        let firstImageSuggestionData = firstImageRecommendation?.growthimagesuggestiondata.first
        XCTAssertEqual(firstImageSuggestionData?.titleText, "Dialer", "Incorrect page title")
        XCTAssertEqual(firstImageSuggestionData?.titleNamespace, 0, "Incorrect title namespace")
        XCTAssertEqual(firstImageSuggestionData?.images.count, 1, "Incorrect images count")

        let firstImageData = firstImageSuggestionData?.images.first
        XCTAssertEqual(firstImageData?.image, "Modem_telefonico.jpg", "Incorrect image file name")
        XCTAssertEqual(firstImageData?.displayFilename, "Modem telefonico.jpg", "Incorrect image display name")
        XCTAssertEqual(firstImageData?.source, "wikipedia", "Incorrect source name")
        XCTAssertEqual(firstImageData?.projects.count, 1, "Incorrect project count")

        let imageMetadata = firstImageData?.metadata
        XCTAssertEqual(imageMetadata?.descriptionUrl, "https://commons.wikimedia.org/wiki/File:Modem_telefonico.jpg", "Incorrect description URL")
        XCTAssertEqual(imageMetadata?.thumbUrl, "//upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Modem_telefonico.jpg/120px-Modem_telefonico.jpg", "Incorrect thumb URL")
        XCTAssertEqual(imageMetadata?.fullUrl, "//upload.wikimedia.org/wikipedia/commons/e/e9/Modem_telefonico.jpg", "Incorrect full URL")
        XCTAssertEqual(imageMetadata?.originalWidth, 1200, "Incorrect width")
        XCTAssertEqual(imageMetadata?.originalHeight, 1600, "Incorrect height")
        XCTAssertEqual(imageMetadata?.mediaType, "BITMAP", "Incorrect mediatype")
        XCTAssertEqual(imageMetadata?.description, "Modem telefonico 2WIRE Con servicio provisto por Telmex.", "Incorrect description")
        XCTAssertEqual(imageMetadata?.author, "<a href=\"//commons.wikimedia.org/w/index.php?title=User:MaryMozqueda&amp;action=edit&amp;redlink=1\" class=\"new\" title=\"User:MaryMozqueda (page does not exist)\">MaryMozqueda</a> / <a rel=\"nofollow\" class=\"external text\" href=\"https://www.flickr.com/photos/43356775@N06/\">Mary Mozqueda</a>", "Incorrect author")
        XCTAssertEqual(imageMetadata?.license, "CC BY 3.0", "Incorrect license")
        XCTAssertEqual(imageMetadata?.date, "2009-10-18", "Incorrect date")
        XCTAssertEqual(imageMetadata?.categories.count, 4, "Incorrect number of categories")
        XCTAssertEqual(imageMetadata?.reason, "Utilizado en el mismo artículo en Wikipedia en lombardo.", "Incorrect reason")
        XCTAssertEqual(imageMetadata?.contentLanguageName, "checo", "Incorrect content language name")
    }

}
