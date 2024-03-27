import XCTest
@testable import Components
@testable import WKData
@testable import WKDataMocks

final class WKImageRecommendationsViewModelTests: XCTestCase {
    
    private let csProject = WKProject.wikipedia(WKLanguage(languageCode: "cs", languageVariantCode: nil))
    private let localizedStrings = WKImageRecommendationsViewModel.LocalizedStrings(title: "Add image", viewArticle: "View Article", onboardingStrings: WKImageRecommendationsViewModel.LocalizedStrings.OnboardingStrings(title: "Onboarding title", firstItemTitle: "First item title", firstItemBody: "First item body", secondItemTitle: "Second item title", secondItemBody: "Second item body", thirdItemTitle: "Third item title", thirdItemBody: "Third item body", continueButton: "Continue", learnMoreButton: "Learn more"), bottomSheetTitle: "Add this image?", yesButtonTitle: "yes", noButtonTitle: "no", notSureButtonTitle: "not sure")

    override func setUpWithError() throws {
        WKDataEnvironment.current.mediaWikiService = WKMockGrowthTasksService()
        WKDataEnvironment.current.basicService = WKMockBasicService()
    }

    func testFetchInitialImageRecommendations() throws {
        let viewModel = WKImageRecommendationsViewModel(project: csProject, semanticContentAttribute: .forceLeftToRight, localizedStrings: localizedStrings)
        
        let expectation = XCTestExpectation(description: "Fetch Image Recommendations")
        
        viewModel.fetchImageRecommendationsIfNeeded {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertEqual(viewModel.imageRecommendations.count, 9, "Unexpected image recommendations count.")
        XCTAssertNotNil(viewModel.currentRecommendation, "currentRecommendation should not be nil after fetching recommendations")
        XCTAssertNotNil(viewModel.currentRecommendation?.articleSummary, "currentRecommendation.articleSummary should not be nil after fetching recommendations")
    }
    
    func testFetchNextImageRecommendation() throws {
        let viewModel = WKImageRecommendationsViewModel(project: csProject, semanticContentAttribute: .forceLeftToRight, localizedStrings: localizedStrings)
        
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
        
        XCTAssertEqual(viewModel.imageRecommendations.count, 8, "Unexpected image recommendations count.")

        XCTAssertNotNil(viewModel.currentRecommendation, "currentRecommendation should not be nil after next()")
        XCTAssertNotNil(viewModel.currentRecommendation?.articleSummary, "currentRecommendation.articleSummary should not be nil after next()")
    }

}
