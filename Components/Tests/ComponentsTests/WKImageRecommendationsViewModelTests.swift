import XCTest
@testable import Components
@testable import WKData
@testable import WKDataMocks

final class WKImageRecommendationsViewModelTests: XCTestCase {
    
    private let csProject = WKProject.wikipedia(WKLanguage(languageCode: "cs", languageVariantCode: nil))
	private let localizedStrings = WKImageRecommendationsViewModel.LocalizedStrings(title: "Add image", viewArticle: "View article", surveyLocalizedStrings: WKImageRecommendationsViewModel.LocalizedStrings.SurveyLocalizedStrings(reason: "Reason", cancel: "Cancel", submit: "Submit", improveSuggestions: "Improve", selectOptions: "Options", imageNotRelevant: "Image not Relevant", notEnoughInformation: "Not enough info", imageIsOffensive: "Image is offensive", imageIsLowQuality: "Image is low quality", dontKnowSubject: "Don't know subject", other: "Other"))

    override func setUpWithError() throws {
        WKDataEnvironment.current.mediaWikiService = WKMockGrowthTasksService()
        WKDataEnvironment.current.basicService = WKMockBasicService()
    }

    func testFetchInitialImageRecommendations() throws {
        let viewModel = WKImageRecommendationsViewModel(project: csProject, localizedStrings: localizedStrings)
        
        let expectation = XCTestExpectation(description: "Fetch Image Recommendations")
        
        viewModel.fetchImageRecommendationsIfNeeded {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(viewModel.recommendations.count, 10, "Unexpected image recommendations count.")
        XCTAssertNotNil(viewModel.currentRecommendation, "currentRecommendation should not be nil after fetching recommendations")
        XCTAssertNotNil(viewModel.currentRecommendation?.articleSummary, "currentRecommendation.articleSummary should not be nil after fetching recommendations")
    }
    
    func testFetchNextImageRecommendation() throws {
        let viewModel = WKImageRecommendationsViewModel(project: csProject, localizedStrings: localizedStrings)
        
        let expectation1 = XCTestExpectation(description: "Fetch Image Recommendations")
        
        viewModel.fetchImageRecommendationsIfNeeded {
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 3.0)
        
        let expectation2 = XCTestExpectation(description: "Fetch Next Image Recommendation")
        viewModel.next {
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 3.0)
        
        XCTAssertEqual(viewModel.recommendations.count, 9, "Unexpected image recommendations count.")
        
        XCTAssertNotNil(viewModel.currentRecommendation, "currentRecommendation should not be nil after next()")
        XCTAssertNotNil(viewModel.currentRecommendation?.articleSummary, "currentRecommendation.articleSummary should not be nil after next()")
    }

}
