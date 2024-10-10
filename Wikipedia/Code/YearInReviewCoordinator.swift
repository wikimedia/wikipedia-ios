import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFYearInReviewCoordinator)
final class YearInReviewCoordinator: NSObject, Coordinator {
    let theme: Theme
    let dataStore: MWKDataStore
    
    var navigationController: UINavigationController
    private weak var viewModel: WMFYearInReviewViewModel?
    private let targetRects = WMFProfileViewTargetRects()
    
    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
    }
    
//    let numberArticles = 63.59
//    let numberLanguages = 332
//    let numberViews = 1.4
//    let numberEditors = 50 // dummy data
//    let numberEdits = 342
//    
//    var baseSlide1Subtitle: String {
//        let format = WMFLocalizedString("year-in-review-base-reading-subtitle", value: "Wikipedia had %1$@ million articles across over %2$@ active languages this year. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review for people without read/edit history, first slide subtitle, %1$@ is replaced with the number of articles, %2$@ is replaced with the number of languages.")
//        return String.localizedStringWithFormat(format, String(numberArticles), String(numberLanguages))
//    }
//    
//    var baseSlide2Title: String {
//        let format = WMFLocalizedString("year-in-review-base-viewed-title", value: "We have viewed Wikipedia articles %1$@ Billion times.", comment: "Year in review for people without read/edit history, second slide title, %1$@ is replaced with the number of article views.")
//        return String.localizedStringWithFormat(format, String(numberViews))
//    }
//    
//    var baseSlide2Subtitle: String {
//        let format = WMFLocalizedString("year-in-review-base-viewed-subtitle", value: "iOS app users have viewed Wikipedia articles %1$@ Billion times. For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact.", comment: "Year in review for people without read/edit history, second slide subtitle, %1$@ is replaced with the number of articles")
//        return String.localizedStringWithFormat(format, String(numberViews))
//    }
//    
//    var baseSlide3Title: String {
//        let format = WMFLocalizedString("year-in-review-base-editors-title", value: "Editors on the iOS app made more than %1$@ edits", comment: "Year in review for people without read/edit history, third slide title, %1$@ is replaced with the number of edits.")
//        return String.localizedStringWithFormat(format, String(numberEditors))
//    }
//    
//    var baseSlide3Subtitle: String {
//        let format = WMFLocalizedString("year-in-review-base-editors-subtitle", value: "Wikipedia's community of volunteer editors made more than %1$@ edits on the iOS app so far this year. The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information.", comment: "Year in review for people without read/edit history, third slide subtitle, %1$@ is replaced with the number of edits")
//        return String.localizedStringWithFormat(format, String(numberEditors))
//    }
//    
//    var baseSlide4Title: String {
//        let format = WMFLocalizedString("year-in-review-base-edits-title", value: "Wikipedia was edited %1$@ times per minute", comment: "Year in review for people without read/edit history, fourth slide title, %1$@ is replaced with the number of edits per minute.")
//        return String.localizedStringWithFormat(format, String(numberEdits))
//    }
//    
//    var baseSlide4Subtitle: String {
//        let format = WMFLocalizedString("year-in-review-base-edits-subtitle", value: "This year, Wikipedia was edited at an average rate of %1$@ times per minute. Articles are collaboratively created and improved using reliable sources. Each edit plays a crucial role in improving and expanding Wikipedia. All of us have knowledge to share, learn how to participate.", comment: "Year in review for people without read/edit history, fourth slide subtitle, %1$@ is replaced with the number of edits per minute")
//        return String.localizedStringWithFormat(format, String(numberEdits))
//    }
    
    func start() {
        // Base case if user has no edit/read history
        let baseFlow: [YearInReviewSlide] = [
            YearInReviewSlide(
                imageName: "heart_yir",
                title: WMFLocalizedString("year-in-review-base-reading-title", value: "Reading brought us together", comment: "Year in review for people without read/edit history, first slide title"),
                informationBubbleText: nil,
                // Purposefully not translated due to numbers
                subtitle: "Wikipedia had 63.59 million articles across over 332 active languages this year. You joined millions in expanding knowledge and exploring diverse topics."),
            YearInReviewSlide(
                imageName: "phone_yir",
                title: "We have viewed Wikipedia articles 1.4 Billion times",
                informationBubbleText: nil,
                subtitle: "iOS app users have viewed Wikipedia articles 1.4 Billion times. For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact."),
            YearInReviewSlide(
                imageName: "languages_yir",
                title: "Editors on the iOS app made more than X edits",
                informationBubbleText: nil,
                subtitle: "Wikipedia's community of volunteer editors made more than X edits on the iOS app so far this year. The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information."),
            YearInReviewSlide(
                imageName: "edit_yir",
                title: "Wikipedia was edited 342 times per minute",
                informationBubbleText: nil,
                subtitle: "This year, Wikipedia was edited at an average rate of 342 times per minute. Articles are collaboratively created and improved using reliable sources. Each edit plays a crucial role in improving and expanding Wikipedia.")
        ]
        
        let localizedStrings = WMFYearInReviewViewModel.LocalizedStrings.init(
            donateButtonTitle: WMFLocalizedString("year-in-review-donate", value: "Donate", comment: "Year in review donate button"),
            doneButtonTitle: WMFLocalizedString("year-in-review-done", value: "Done", comment: "Year in review done button"),
            shareButtonTitle: WMFLocalizedString("year-in-review-share", value: "Share", comment: "Year in review share button"),
            nextButtonTitle: WMFLocalizedString("year-in-review-next", value: "Next", comment: "Year in review next button"),
            firstSlideTitle: WMFLocalizedString("year-in-review-title", value: "Explore your Wikipedia Year in Review", comment: "Year in review page title"),
            firstSlideSubtitle: WMFLocalizedString("year-in-review-subtitle", value: "See insights about which articles you read on the Wikipedia app and the edits you made. Share your journey and discover what stood out for you this year. Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.", comment: "Year in review page information"),
            firstSlideCTA: WMFLocalizedString("year-in-review-get-started", value: "Get Started", comment: "Button to continue to year in review"),
            firstSlideHide: WMFLocalizedString("year-in-review-hide", value: "Hide this feature", comment: "Button to hide year in review feature")
        )
        
        let viewModel = WMFYearInReviewViewModel(localizedStrings: localizedStrings, slides: baseFlow)

        var yirview = WMFYearInReview(viewModel: viewModel)
        
        yirview.donePressed = { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        }
        
        self.viewModel = viewModel
        let finalView = yirview.environmentObject(targetRects) 
        let hostingController = UIHostingController(rootView: finalView)
        hostingController.modalPresentationStyle = .pageSheet
        
        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = false
        }
        
        navigationController.present(hostingController, animated: true, completion: nil)
    }
}
