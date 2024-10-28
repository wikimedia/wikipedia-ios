import Foundation
import SwiftUI

public class WMFYearInReviewViewModel: ObservableObject {
    // Edge slide refers to one at either the beginning or the end
    @Published var isEdgeSlide = true
    @Published var hasDonated = false
    @Published var currentSlide = 0

    public let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlideContent]
    let username: String?
    public let shareLink: String
    public let hashtag: String
    weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    @Published public var isLoading: Bool = false
    private var isFirstSlide = true

    public init(isEdgeSlide: Bool = true, localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent], username: String?, shareLink: String, hashtag: String, coordinatorDelegate: YearInReviewCoordinatorDelegate?, hasDonated: Bool = false) {
        self.isEdgeSlide = isEdgeSlide
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.username = username
        self.shareLink = shareLink
        self.hashtag = hashtag
        self.coordinatorDelegate = coordinatorDelegate
        self.hasDonated = false
    }

    public func getStarted() {
        isEdgeSlide = false
        isFirstSlide = false
    }

    public struct LocalizedStrings {
        let donateButtonTitle: String
        let doneButtonTitle: String
        let shareButtonTitle: String
        let nextButtonTitle: String
        let finishButtonTitle: String
        let firstSlideTitle: String
        let firstSlideSubtitle: String
        let firstSlideCTA: String
        let firstSlideHide: String
        let lastSlideCTA: String
        let lastSlideDonate: String
        public let shareText: String
        public let usernameTitle: String
        
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, firstSlideTitle: String, firstSlideSubtitle: String, firstSlideCTA: String, firstSlideHide: String, lastSlideCTA: String, lastSlideDonate: String, shareText: String, usernameTitle: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.finishButtonTitle = finishButtonTitle
            self.firstSlideTitle = firstSlideTitle
            self.firstSlideSubtitle = firstSlideSubtitle
            self.firstSlideCTA = firstSlideCTA
            self.firstSlideHide = firstSlideHide
            self.lastSlideCTA = lastSlideCTA
            self.lastSlideDonate = lastSlideDonate
            self.shareText = shareText
            self.usernameTitle = usernameTitle
        }
    }
    
    public func shouldShowDonate() -> Bool {
        if isFirstSlide {
            return false
        } else if isEdgeSlide {
            return !hasDonated
        }
        return false
    }

    public func shouldShowFinish() -> Bool {
        return hasDonated && currentSlide == slides.count - 1
    }
    
    public func shouldShowToolbar() -> Bool {
        if isFirstSlide {
            return false
        } else {
            if !isEdgeSlide {
                return true
            }
            return isEdgeSlide && hasDonated
        }
    }

    func getFomattedUsername() -> String? {
        if let username {
            return "\(localizedStrings.usernameTitle):\(username)"
        }
        return nil
    }

    func handleShare(for slide: Int) {
        let view = WMFYearInReviewShareableSlideView(slide: slide, slideImage: slides[slide].imageName, slideTitle: slides[slide].title, slideSubtitle: slides[slide].subtitle, hashtag: hashtag, username: getFomattedUsername())
        let shareView = view.snapshot()
        coordinatorDelegate?.handleYearInReviewAction(.share(image: shareView))
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
