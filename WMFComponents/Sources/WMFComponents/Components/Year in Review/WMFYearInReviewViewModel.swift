import Foundation
import SwiftUI

public class WMFYearInReviewViewModel: ObservableObject {
    @Published var isFirstSlide = true
    let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlideContent]
    let username: String?
    let shareLink: String
    let hashtag = "#WikipediaYearInReview"

    weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?

    public init(isFirstSlide: Bool = true, localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent], username: String?, shareLink: String, coordinatorDelegate: YearInReviewCoordinatorDelegate?) {
        self.isFirstSlide = isFirstSlide
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.username = username
        self.shareLink = shareLink
        self.coordinatorDelegate = coordinatorDelegate
    }

    public func getStarted() {
        isFirstSlide = false
    }

    public struct LocalizedStrings {
        let donateButtonTitle: String
        let doneButtonTitle: String
        let shareButtonTitle: String
        let nextButtonTitle: String
        let firstSlideTitle: String
        let firstSlideSubtitle: String
        let firstSlideCTA: String
        let firstSlideHide: String
        let shareText: String
        let usernameTitle: String

        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, firstSlideTitle: String, firstSlideSubtitle: String, firstSlideCTA: String, firstSlideHide: String, shareText: String, usernameTitle: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.firstSlideTitle = firstSlideTitle
            self.firstSlideSubtitle = firstSlideSubtitle
            self.firstSlideCTA = firstSlideCTA
            self.firstSlideHide = firstSlideHide
            self.shareText = shareText
            self.usernameTitle = usernameTitle
        }

    }

    func handleShare(for slide: Int) {
        coordinatorDelegate?.handleYearInReviewAction(.share(slide: slide))
    }

}

public struct YearInReviewSlideContent: SlideShowProtocol {
    public let imageName: String
    public let title: String
    let informationBubbleText: String?
    public let subtitle: String

    public init(imageName: String, title: String, informationBubbleText: String?, subtitle: String) {
        self.imageName = imageName
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
    }
}

// temp - waiting for the donate action to be merged

public protocol YearInReviewCoordinatorDelegate: AnyObject {
    func handleYearInReviewAction(_ action: YearInReviewCoordinatorAction)
}

public enum YearInReviewCoordinatorAction {
    case share(slide: Int)
}
