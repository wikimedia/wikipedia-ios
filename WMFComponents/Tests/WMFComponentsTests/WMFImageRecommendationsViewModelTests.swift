import XCTest
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

final class WMFImageRecommendationsViewModelTests: XCTestCase {
    
    private let csProject = WMFProject.wikipedia(WMFLanguage(languageCode: "cs", languageVariantCode: nil))
    
    private let localizedStrings = WMFImageRecommendationsViewModel.LocalizedStrings(title: "Add image", viewArticle: "View article", onboardingStrings: WMFImageRecommendationsViewModel.LocalizedStrings.OnboardingStrings(title: "Onboarding title", firstItemTitle: "First item title", firstItemBody: "First item body", secondItemTitle: "Second item title", secondItemBody: "Second item body", thirdItemTitle: "Third item title", thirdItemBody: "Third item body", continueButton: "Continue", learnMoreButton: "Learn more"), surveyLocalizedStrings: WMFImageRecommendationsViewModel.LocalizedStrings.SurveyLocalizedStrings(title: "Reason", cancel: "Cancel", submit: "Submit", subtitle: "Improve", instructions: "Instructions", otherPlaceholder: "Other"), emptyLocalizedStrings: WMFImageRecommendationsViewModel.LocalizedStrings.EmptyLocalizedStrings(title: "You have no more suggested images available at this time.", subtitle: "Try coming back later.", titleFilter: nil, buttonTitle: nil, attributedFilterString: nil), errorLocalizedStrings: WMFImageRecommendationsViewModel.LocalizedStrings.ErrorLocalizedStrings(title: "Unable to load page", subtitle: "Something went wrong.", buttonTitle: "Try again"), firstTooltipStrings: WMFTooltipViewModel.LocalizedStrings(title:"Review", body:"Review this article to understand its topic.", buttonTitle: "Next"), secondTooltipStrings: WMFTooltipViewModel.LocalizedStrings(title:"Inspect", body:"Inspect the image and its associated information.", buttonTitle: "Next"), thirdTooltipStrings: WMFTooltipViewModel.LocalizedStrings(title:"Decide", body:"Decide if the image helps readers understand this topic better.", buttonTitle: "OK"), altTextFeedbackStrings: WMFImageRecommendationsViewModel.LocalizedStrings.AltTextFeedbackStrings(feedbackTitle: "Feedback title", feedbackSubtitle: "Feedback subtite", yesButton: "Yes", noButton: "No"), bottomSheetTitle: "Add this image?", yesButtonTitle: "yes", noButtonTitle: "no", notSureButtonTitle: "not sure", learnMoreButtonTitle: "Learn more", tutorialButtonTitle: "Tutorial", problemWithFeatureButtonTitle: "Problem with feature")
    
    private let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: "Image is not relevant", apiIdentifer: "notrelevant"),
            WMFSurveyViewModel.OptionViewModel(text: "Not enough information to decide", apiIdentifer: "noinfo"),
            WMFSurveyViewModel.OptionViewModel(text: "Image is offensive", apiIdentifer: "offensive"),
            WMFSurveyViewModel.OptionViewModel(text: "Image is low quality", apiIdentifer: "lowquality"),
            WMFSurveyViewModel.OptionViewModel(text: "I don’t know this subject", apiIdentifer: "unfamiliar")
    ]

    override func setUpWithError() throws {
        WMFDataEnvironment.current.mediaWikiService = WMFMockGrowthTasksService()
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
    }

    func testFetchInitialImageRecommendations() throws {
        let viewModel = WMFImageRecommendationsViewModel(project: csProject, semanticContentAttribute: .forceLeftToRight, isPermanent: true, localizedStrings: localizedStrings, surveyOptions: surveyOptions, needsSuppressPosting: false)

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
        let viewModel = WMFImageRecommendationsViewModel(project: csProject, semanticContentAttribute: .forceLeftToRight, isPermanent: true, localizedStrings: localizedStrings, surveyOptions: surveyOptions, needsSuppressPosting: false)
        
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
