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
    
    func start() {
        Task {
            
        }
        // NOTE: To be translated when grabbed from data source / migrated - this is all example data
        let slides: [YearInReviewSlideContent] = [
            YearInReviewSlideContent(
                imageName: "heart_yir",
                title: "You read 350 articles this year",
                informationBubbleText: "Top languages: English, German, French",
                subtitle: "You read 350 articles this year in English, German, and French. This year Wikipedia had 63.59 million articles available across over 332 active languages. You joined millions in expanding knowledge and exploring diverse topics."
            ),
            YearInReviewSlideContent(
                imageName: "languages_yir",
                title: "Top Viewed Articles",
                informationBubbleText: "Most viewed: History of Art",
                subtitle: "You explored topics like History of Art, Climate Change, and Artificial Intelligence. These were among the most viewed subjects globally, with millions of views from around the world."
            ),
            YearInReviewSlideContent(
                imageName: "phone_yir",
                title: "Your Contributions",
                informationBubbleText: "Edits: 45, Featured: 2",
                subtitle: "This year, you made 45 edits, with 2 of them featured. Your contributions helped improve the quality and reach of Wikipedia's vast collection of knowledge."
            ),
            YearInReviewSlideContent(
                imageName: "edit_yir",
                title: "Article Growth",
                informationBubbleText: "New articles: 12",
                subtitle: "You contributed to 12 new articles this year. Wikipedia's collection continues to grow, now with over 63.59 million articles in over 332 languages."
            ),
            YearInReviewSlideContent(
                imageName: "savedarticles_yir",
                title: "A Year in Review",
                informationBubbleText: "Your Wiki Year",
                subtitle: "Looking back at your Wikipedia journey this year, you've helped expand knowledge and contributed to a vibrant and growing community."
            )
        ]
        
        let localizedStrings = WMFYearInReviewViewModel.LocalizedStrings.init(
            donateButtonTitle: WMFLocalizedString("year-in-review-donate", value: "Donate", comment: "Year in review donate button"),
            doneButtonTitle: WMFLocalizedString("year-in-review-done", value: "Done", comment: "Year in review done button"),
            shareButtonTitle: WMFLocalizedString("year-in-review-share", value: "Share", comment: "Year in review share button"),
            nextButtonTitle: WMFLocalizedString("year-in-review-next", value: "Next", comment: "Year in review next button"))
        
        let viewModel = WMFYearInReviewViewModel(localizedStrings: localizedStrings, slides: slides)

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
