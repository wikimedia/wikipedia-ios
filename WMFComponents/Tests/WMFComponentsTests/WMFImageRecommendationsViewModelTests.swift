import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite(.serialized)
final class WMFImageRecommendationsViewModelTests {
    
    private let fixture = WMFDataTestFixture()
    private let csProject = WMFProject.wikipedia(WMFLanguage(languageCode: "cs", languageVariantCode: nil))
    
    private let localizedStrings = WMFImageRecommendationsViewModel.LocalizedStrings(title: "Add image", viewArticle: "View article", onboardingStrings: WMFImageRecommendationsViewModel.LocalizedStrings.OnboardingStrings(title: "Onboarding title", firstItemTitle: "First item title", firstItemBody: "First item body", secondItemTitle: "Second item title", secondItemBody: "Second item body", thirdItemTitle: "Third item title", thirdItemBody: "Third item body", continueButton: "Continue", learnMoreButton: "Learn more"), tooltipStrings: WMFImageRecommendationsViewModel.LocalizedStrings.TooltipStrings(tooltip1Title: "Review", tooltip1Body: "Review this article to understand its topic.", tooltip2Title: "Inspect", tooltip2Body: "Inspect the image and its associated information.", tooltip3Title: "Decide", tooltip3Body: "Decide if the image helps readers understand this topic better."), surveyLocalizedStrings: WMFImageRecommendationsViewModel.LocalizedStrings.SurveyLocalizedStrings(title: "Reason", cancel: "Cancel", submit: "Submit", subtitle: "Improve", instructions: "Instructions", otherPlaceholder: "Other"), emptyLocalizedStrings: WMFImageRecommendationsViewModel.LocalizedStrings.EmptyLocalizedStrings(title: "You have no more suggested images available at this time.", subtitle: "Try coming back later.", titleFilter: nil, buttonTitle: nil, attributedFilterString: nil), errorLocalizedStrings: WMFImageRecommendationsViewModel.LocalizedStrings.ErrorLocalizedStrings(title: "Unable to load page", subtitle: "Something went wrong.", buttonTitle: "Try again"), bottomSheetTitle: "Add this image?", yesButtonTitle: "yes", noButtonTitle: "no", notSureButtonTitle: "not sure", learnMoreButtonTitle: "Learn more", tutorialButtonTitle: "Tutorial", problemWithFeatureButtonTitle: "Problem with feature")
    private let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: "Image is not relevant", apiIdentifer: "notrelevant"),
            WMFSurveyViewModel.OptionViewModel(text: "Not enough information to decide", apiIdentifer: "noinfo"),
            WMFSurveyViewModel.OptionViewModel(text: "Image is offensive", apiIdentifer: "offensive"),
            WMFSurveyViewModel.OptionViewModel(text: "Image is low quality", apiIdentifer: "lowquality"),
            WMFSurveyViewModel.OptionViewModel(text: "I don’t know this subject", apiIdentifer: "unfamiliar")
    ]

    @Test
    func fetchInitialImageRecommendations() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFImageRecommendationsViewModel(project: csProject, semanticContentAttribute: .forceLeftToRight, isPermanent: true, localizedStrings: localizedStrings, surveyOptions: surveyOptions, needsSuppressPosting: false)

            await viewModel.fetchImageRecommendationsIfNeeded()

            #expect(viewModel.imageRecommendations.count == 9)
            #expect(viewModel.currentRecommendation != nil)
            #expect(viewModel.currentRecommendation?.articleSummary != nil)
        }
    }
    
    @Test
    func fetchNextImageRecommendation() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = WMFImageRecommendationsViewModel(project: csProject, semanticContentAttribute: .forceLeftToRight, isPermanent: true, localizedStrings: localizedStrings, surveyOptions: surveyOptions, needsSuppressPosting: false)

            await viewModel.fetchImageRecommendationsIfNeeded()
            await viewModel.next()

            #expect(viewModel.imageRecommendations.count == 8)
            #expect(viewModel.currentRecommendation != nil)
            #expect(viewModel.currentRecommendation?.articleSummary != nil)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.mediaWikiService = WMFMockGrowthTasksService()
        WMFDataEnvironment.current.basicService = WMFMockBasicService()
    }
}

private extension WMFImageRecommendationsViewModel {
    func fetchImageRecommendationsIfNeeded() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            fetchImageRecommendationsIfNeeded {
                continuation.resume()
            }
        }
    }

    func next() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            next {
                continuation.resume()
            }
        }
    }
}
