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
        let slides: [YearInReviewSlide] = [
            YearInReviewSlide(
                imageName: "book.fill",
                title: "You read 350 articles this year",
                informationBubbleText: "Top languages: English, German, French",
                subtitle: "You read 350 articles this year in English, German, and French. This year Wikipedia had 63.59 million articles available across over 332 active languages. You joined millions in expanding knowledge and exploring diverse topics."
            ),
            YearInReviewSlide(
                imageName: "globe",
                title: "Top Viewed Articles",
                informationBubbleText: "Most viewed: History of Art",
                subtitle: "You explored topics like History of Art, Climate Change, and Artificial Intelligence. These were among the most viewed subjects globally, with millions of views from around the world."
            ),
            YearInReviewSlide(
                imageName: "person.2.fill",
                title: "Your Contributions",
                informationBubbleText: "Edits: 45, Featured: 2",
                subtitle: "This year, you made 45 edits, with 2 of them featured. Your contributions helped improve the quality and reach of Wikipedia's vast collection of knowledge."
            ),
            YearInReviewSlide(
                imageName: "chart.bar.fill",
                title: "Article Growth",
                informationBubbleText: "New articles: 12",
                subtitle: "You contributed to 12 new articles this year. Wikipedia's collection continues to grow, now with over 63.59 million articles in over 332 languages."
            ),
            YearInReviewSlide(
                imageName: "calendar",
                title: "A Year in Review",
                informationBubbleText: "Your Wiki Year",
                subtitle: "Looking back at your Wikipedia journey this year, you've helped expand knowledge and contributed to a vibrant and growing community."
            )
        ]

        var yirview = WMFYearInReview(slides: slides)
        
        yirview.donePressed = { [weak self] in
            self?.navigationController.dismiss(animated: true, completion: nil)
        }
        
        let viewModel = WMFYearInReviewViewModel()
        
        self.viewModel = viewModel
        let finalView = yirview.environmentObject(targetRects) // TODO: ask about targetRects
        let hostingController = UIHostingController(rootView: finalView)
        hostingController.modalPresentationStyle = .pageSheet
        
        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = false
        }
        
        navigationController.present(hostingController, animated: true, completion: nil)
    }
}
