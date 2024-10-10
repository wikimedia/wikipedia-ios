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
    
    let numberArticles = 63.59
    let numberLanguages = 332
    let numberViews = 1.4
    
    var baseSlide1Subtitle: String {
        let format = WMFLocalizedString("year-in-review-base-reading-subtitle", value: "Wikipedia had %1$@ million articles across over %2$@ active languages this year. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review for people without read/edit history, first slide subtitle, %1$@ is replaced with the number of articles, %2$@ is replaced with the number of languages.")
        return String.localizedStringWithFormat(format, String(numberArticles), String(numberLanguages))
    }
    
    var baseSlide2Subtitle: String {
        let format = WMFLocalizedString("year-in-review-base-viewed-subtitle", value: "iOS app users have viewed Wikipedia articles %1$@ Billion times. For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact.", comment: "Year in review for people without read/edit history, first slide subtitle, %1$@ is replaced with the number of articles, %2$@ is replaced with the number of languages.")
        return String.localizedStringWithFormat(format, String(numberViews))
    }
    
    var baseSlide2Title: String {
        let format = WMFLocalizedString("year-in-review-base-viewed-title", value: "We have viewed Wikipedia articles %1$@ Billion times.", comment: "Year in review for people without read/edit history, second slide title, %1$@ is replaced with the number of article views.")
        return String.localizedStringWithFormat(format, String(numberViews))
    }
    
    func start() {
        // Base case if user has no edit/read history
        let baseFlow: [YearInReviewSlide] = [
            YearInReviewSlide(
                imageName: "heart_yir",
                title: WMFLocalizedString("year-in-review-base-reading-title", value: "Reading brought us together", comment: "Year in review for people without read/edit history, first slide title"),
                informationBubbleText: nil,
                subtitle: baseSlide1Subtitle),
            YearInReviewSlide(
                imageName: "phone_yir",
                title: baseSlide2Title,
                informationBubbleText: nil,
                subtitle: baseSlide2Subtitle)
        ]
        
        /*
         Wikipedia had 63.59 million articles across over 332 active languages this year. You joined millions in expanding knowledge and exploring diverse topics.
         
         
         var emailRepresentation: String {
             let format = WMFLocalizedString("share-email-format", value: "“%1$@”\n\nfrom “%2$@”\n\n%3$@", comment: "Share format string for email. %1$@ is replaced with the selected text, %2$@ is replaced with the article title, %3$@ is replaced with the articleURL.")
             return String.localizedStringWithFormat(format, text, articleTitle, articleURL.wmf_URLForImageSharing.absoluteString)
         }
         */
        
        
//        // NOTE: To be translated when grabbed from data source / migrated - this is all example data
//        let slides: [YearInReviewSlide] = [
//            YearInReviewSlide(
//                imageName: "heart_yir",
//                title: "You read 350 articles this year",
//                informationBubbleText: "Top languages: English, German, French",
//                subtitle: "You read 350 articles this year in English, German, and French. This year Wikipedia had 63.59 million articles available across over 332 active languages. You joined millions in expanding knowledge and exploring diverse topics."
//            ),
//            YearInReviewSlide(
//                imageName: "languages_yir",
//                title: "Top Viewed Articles",
//                informationBubbleText: "Most viewed: History of Art",
//                subtitle: "You explored topics like History of Art, Climate Change, and Artificial Intelligence. These were among the most viewed subjects globally, with millions of views from around the world."
//            ),
//            YearInReviewSlide(
//                imageName: "phone_yir",
//                title: "Your Contributions",
//                informationBubbleText: "Edits: 45, Featured: 2",
//                subtitle: "This year, you made 45 edits, with 2 of them featured. Your contributions helped improve the quality and reach of Wikipedia's vast collection of knowledge."
//            ),
//            YearInReviewSlide(
//                imageName: "edit_yir",
//                title: "Article Growth",
//                informationBubbleText: "New articles: 12",
//                subtitle: "You contributed to 12 new articles this year. Wikipedia's collection continues to grow, now with over 63.59 million articles in over 332 languages."
//            ),
//            YearInReviewSlide(
//                imageName: "savedarticles_yir",
//                title: "A Year in Review",
//                informationBubbleText: "Your Wiki Year",
//                subtitle: "Looking back at your Wikipedia journey this year, you've helped expand knowledge and contributed to a vibrant and growing community."
//            )
//        ]
        
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
