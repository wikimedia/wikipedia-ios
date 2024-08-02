import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFGrowthTasksDataControllerTests: XCTestCase {

    private let csProject = WMFProject.wikipedia(WMFLanguage(languageCode: "cs", languageVariantCode: nil))
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    override func setUp() async throws {
        WMFDataEnvironment.current.mediaWikiService = WMFMockGrowthTasksService()
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
    }
    
    func testFetchImageRecommendationCombinedForTasks() {

        let controller = WMFGrowthTasksDataController(project: csProject)
        let expectation = XCTestExpectation(description: "Fetch Image Recommendations")

        var imageRecsToTest: [WMFImageRecommendation.Page]?

        controller.getImageRecommendationsCombined(completion: { result in
            switch result {
            case .success(let response):
                imageRecsToTest = response
            case .failure(let error):
                XCTFail("Failed to fetch Image Recommendations \(error)")
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 10.0)

        XCTAssertTrue(imageRecsToTest != nil)
    }
    
    func testParseImageRecommendationsCombined() {

        let controller = WMFGrowthTasksDataController(project: enProject)
        var imageRecsToTest: [WMFImageRecommendation.Page]?

        controller.getImageRecommendationsCombined(completion: { result in
            switch result {
            case .success(let response):
                imageRecsToTest = response
            case .failure(let error):
                XCTFail("Failed to fetch Image Recommendations \(error)")
            }
        })

        guard let imageRecsToTest else {
            XCTFail("Failed to retrieve image recommendations")
            return
        }

        let firstImageRecommendation = imageRecsToTest.first
        XCTAssertEqual(firstImageRecommendation?.pageid, 6706133, "Incorrect page Id")
        XCTAssertEqual(firstImageRecommendation?.title, "Juan de Salmerón", "Incorrect page title")
        XCTAssertEqual(firstImageRecommendation?.growthimagesuggestiondata?.count, 1, "Incorrect growth suggestion data count")


        let firstImageSuggestionData = firstImageRecommendation?.growthimagesuggestiondata?.first
        XCTAssertEqual(firstImageSuggestionData?.titleText, "Juan de Salmerón", "Incorrect page title")
        XCTAssertEqual(firstImageSuggestionData?.titleNamespace, 0, "Incorrect title namespace")
        XCTAssertEqual(firstImageSuggestionData?.images.count, 1, "Incorrect images count")

        let firstImageData = firstImageSuggestionData?.images.first
        XCTAssertEqual(firstImageData?.image, "Juan_de_Salmerón.JPG", "Incorrect image file name")
        XCTAssertEqual(firstImageData?.displayFilename, "Juan de Salmerón.JPG", "Incorrect image display name")
        XCTAssertEqual(firstImageData?.source, "wikipedia", "Incorrect source name")
        XCTAssertEqual(firstImageData?.projects.count, 1, "Incorrect project count")

        let imageMetadata = firstImageData?.metadata
        XCTAssertEqual(imageMetadata?.descriptionUrl, "https://commons.wikimedia.org/wiki/File:Juan_de_Salmer%C3%B3n.JPG", "Incorrect description URL")
        XCTAssertEqual(imageMetadata?.thumbUrl, "//upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Juan_de_Salmer%C3%B3n.JPG/120px-Juan_de_Salmer%C3%B3n.JPG", "Incorrect thumb URL")
        XCTAssertEqual(imageMetadata?.fullUrl, "//upload.wikimedia.org/wikipedia/commons/d/d0/Juan_de_Salmer%C3%B3n.JPG", "Incorrect full URL")
        XCTAssertEqual(imageMetadata?.originalWidth, 764, "Incorrect width")
        XCTAssertEqual(imageMetadata?.originalHeight, 1090, "Incorrect height")
        XCTAssertEqual(imageMetadata?.mediaType, "BITMAP", "Incorrect mediatype")
        XCTAssertEqual(imageMetadata?.description, "El Licenciado Juan de Salmerón, fundador de Puebla", "Incorrect description")
        XCTAssertEqual(imageMetadata?.author, "<a href=\"//commons.wikimedia.org/wiki/User:Gusvel\" title=\"User:Gusvel\">Gusvel</a>", "Incorrect author")
        XCTAssertEqual(imageMetadata?.license, "CC BY-SA 4.0", "Incorrect license")
        XCTAssertEqual(imageMetadata?.date, "2010-10-19", "Incorrect date")
        XCTAssertEqual(imageMetadata?.categories.count, 1, "Incorrect number of categories")
        XCTAssertEqual(imageMetadata?.reason, "Used in the same article in Spanish Wikipedia.", "Incorrect reason")
        XCTAssertEqual(imageMetadata?.contentLanguageName, "English", "Incorrect content language name")
    }
    
    func testFetchArticleSummary() {
        
        let expectation = XCTestExpectation(description: "Fetch Article Summary")
        
        let controller = WMFArticleSummaryDataController()
        
        var articleSummaryToTest: WMFArticleSummary?
        controller.fetchArticleSummary(project: csProject, title: "Novela (právo)") { result in
            switch result {
            case .success(let articleSummary):
                
                articleSummaryToTest = articleSummary
                
            case .failure(let error):
                XCTFail("Failure getting article summary: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        guard let articleSummaryToTest else {
            XCTFail("Missing articleSummaryToTest")
            return
        }
        
        XCTAssertEqual(articleSummaryToTest.displayTitle, "<span class=\"mw-page-title-main\">Novela (právo)</span>", "Incorrect displayTitle")
        XCTAssertEqual(articleSummaryToTest.description, "změna zákona", "Incorrect description")
        XCTAssertEqual(articleSummaryToTest.extractHtml, "<p><b>Novelou</b> se nazývá takový právní předpis, kterým se mění či doplňuje, cizím slovem <i>novelizuje</i>, jiný právní předpis. Novely jsou vydávány buď jako samostatné právní předpisy nebo jsou připojeny k jiným předpisům zpravidla na jejich konec. Název se odvozuje od výrazu „Novellae“, což je sbírka nařízení císaře Justiniána I. z let 534–569, která byla zařazena do souboru římského práva Corpus iuris civilis jako dodatek. Odlišným od novelizace je výraz „novace“, který má místo v soukromém právu, kde jde o novace závazků.</p>", "Incorrect extractHtml")
    }

}
