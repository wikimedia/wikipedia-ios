import Foundation
import SwiftUI

public protocol WMFYearInReviewLoggingDelegate: AnyObject {
    func logYearInReviewIntroDidTapContinue()
    func logYearInReviewIntroDidTapDisable()
    func logYearInReviewSlideDidAppear(slideLoggingID: String)
    func logYearInReviewDidTapDone(slideLoggingID: String)
    func logYearInReviewDidTapNext(slideLoggingID: String)
}

public class WMFYearInReviewViewModel: ObservableObject {
    @Published var isFirstSlide = true
    @Published var currentSlide = 0
    public let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlideContent]
    let username: String?
    public let shareLink: String
    public let hashtag: String
    let hasPersonalizedDonateSlide: Bool
    weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    private(set) weak var loggingDelegate: WMFYearInReviewLoggingDelegate?
        
    @Published public var isLoading: Bool = false

    public init(isFirstSlide: Bool = true, localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent], username: String?, shareLink: String, hashtag: String, hasPersonalizedDonateSlide: Bool, coordinatorDelegate: YearInReviewCoordinatorDelegate?, loggingDelegate: WMFYearInReviewLoggingDelegate) {
        self.isFirstSlide = isFirstSlide
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.username = username
        self.shareLink = shareLink
        self.hasPersonalizedDonateSlide = hasPersonalizedDonateSlide
        self.hashtag = hashtag
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
    }

    public func getStarted() {
        isFirstSlide = false
    }
    
    public func nextSlide() {
        if isLastSlide {
            coordinatorDelegate?.handleYearInReviewAction(.dismiss(isLastSlide: true))
        } else {
            currentSlide = (currentSlide + 1) % slides.count
        }
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
        public let shareText: String
        public let usernameTitle: String

        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, firstSlideTitle: String, firstSlideSubtitle: String, firstSlideCTA: String, firstSlideHide: String, shareText: String, usernameTitle: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.finishButtonTitle = finishButtonTitle
            self.firstSlideTitle = firstSlideTitle
            self.firstSlideSubtitle = firstSlideSubtitle
            self.firstSlideCTA = firstSlideCTA
            self.firstSlideHide = firstSlideHide
            self.shareText = shareText
            self.usernameTitle = usernameTitle
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
    
    func handleDone() {
        coordinatorDelegate?.handleYearInReviewAction(.dismiss(isLastSlide: isLastSlide))
    }
    
    func handleDonate(sourceRect: CGRect) {
        coordinatorDelegate?.handleYearInReviewAction(.donate(sourceRect: sourceRect, slideLoggingID: slideLoggingID))
    }
    
    func handleLearnMore(url: URL) {
        coordinatorDelegate?.handleYearInReviewAction(.learnMore(url: url, fromPersonalizedDonateSlide: hasPersonalizedDonateSlide))
    }
    
    func logYearInReviewSlideDidAppear() {
        loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: slideLoggingID)
    }
    
    public func logYearInReviewDidTapDone() {
        loggingDelegate?.logYearInReviewDidTapDone(slideLoggingID: slideLoggingID)
    }
    
    func logYearInReviewSlideDidTapNext() {
        loggingDelegate?.logYearInReviewDidTapNext(slideLoggingID: slideLoggingID)
    }
    
    var slideLoggingID: String {
        return isFirstSlide ? "start" : slides[currentSlide].loggingID
    }
    
    var isLastSlide: Bool {
        return currentSlide == slides.count - 1
    }
    
    var shouldShowDonateButton: Bool {
        let slide = slides[currentSlide]
        return !isFirstSlide && !slide.hideDonateButton
    }
    
    var shouldShowWLogo: Bool {
        return !isFirstSlide
    }
}

public struct YearInReviewSlideContent: SlideShowProtocol {
    public let imageName: String
    public let imageOverlay: String?
    public let textOverlay: String?
    public let title: String
    let informationBubbleText: String?
    public let subtitle: String
    public let loggingID: String
    public let hideDonateButton: Bool
    
    public init(imageName: String, imageOverlay: String? = nil, textOverlay: String? = nil, title: String, informationBubbleText: String?, subtitle: String, loggingID: String, hideDonateButton: Bool) {
        self.imageName = imageName
        self.imageOverlay = imageOverlay
        self.textOverlay = textOverlay
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
        self.loggingID = loggingID
        self.hideDonateButton = hideDonateButton
    }
}
