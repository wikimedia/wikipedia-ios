import Foundation
import SwiftUI
import WMFData

public protocol WMFYearInReviewLoggingDelegate: AnyObject {
    func logYearInReviewIntroDidTapContinue()
    func logYearInReviewIntroDidTapLearnMore()
    func logYearInReviewDonateDidTapLearnMore(slideLoggingID: String)
    func logYearInReviewSlideDidAppear(slideLoggingID: String)
    func logYearInReviewDidTapDone(slideLoggingID: String)
    func logYearInReviewDidTapNext(slideLoggingID: String)
    func logYearInReviewDidTapDonate(slideLoggingID: String)
    func logYearInReviewDidTapShare(slideLoggingID: String)
}

public class WMFYearInReviewViewModel: ObservableObject {
    @Published var isFirstSlide = true
    @Published var currentSlide = 0
    public let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlideContent]
    public let shareLink: String
    public let hashtag: String
    let hasPersonalizedDonateSlide: Bool
    weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    weak var badgeDelegate: YearInReviewBadgeDelegate?
    private(set) weak var loggingDelegate: WMFYearInReviewLoggingDelegate?
        
    @Published public var isLoading: Bool = false

    public init(isFirstSlide: Bool = true, localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent], shareLink: String, hashtag: String, hasPersonalizedDonateSlide: Bool, coordinatorDelegate: YearInReviewCoordinatorDelegate?, loggingDelegate: WMFYearInReviewLoggingDelegate, badgeDelegate: YearInReviewBadgeDelegate?) {
        self.isFirstSlide = isFirstSlide
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.shareLink = shareLink
        self.hasPersonalizedDonateSlide = hasPersonalizedDonateSlide
        self.hashtag = hashtag
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.badgeDelegate = badgeDelegate
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
        let firstSlideLearnMore: String
        public let shareText: String

        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, firstSlideTitle: String, firstSlideSubtitle: String, firstSlideCTA: String, firstSlideLearnMore: String, shareText: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.finishButtonTitle = finishButtonTitle
            self.firstSlideTitle = firstSlideTitle
            self.firstSlideSubtitle = firstSlideSubtitle
            self.firstSlideCTA = firstSlideCTA
            self.firstSlideLearnMore = firstSlideLearnMore
            self.shareText = shareText
        }

    }

    func handleShare(for slide: Int) {
        let view = WMFYearInReviewShareableSlideView(imageName: slides[slide].imageName, imageOverlay: slides[slide].imageOverlay, textOverlay: slides[slide].textOverlay, slideTitle: slides[slide].title, slideSubtitle: slides[slide].subtitle, hashtag: hashtag)
        let shareView = view.snapshot()
        coordinatorDelegate?.handleYearInReviewAction(.share(image: shareView))
    }
    
    func handleDone() {
        coordinatorDelegate?.handleYearInReviewAction(.dismiss(isLastSlide: isLastSlide))
    }
    
    func handleDonate(sourceRect: CGRect) {
        coordinatorDelegate?.handleYearInReviewAction(.donate(sourceRect: sourceRect))
    }
    
    func handleLearnMore(url: URL) {
        var shouldShowDonate = false
        if slides.count - 1 == currentSlide && !hasPersonalizedDonateSlide {
            shouldShowDonate = true
        }
        coordinatorDelegate?.handleYearInReviewAction(.learnMore(url: url, shouldShowDonateButton: shouldShowDonate))
        loggingDelegate?.logYearInReviewDonateDidTapLearnMore(slideLoggingID: slideLoggingID)
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
    
    func logYearInReviewDidTapDonate() {
        loggingDelegate?.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID)
    }
    
    func logYearInReviewDidTapShare() {
        loggingDelegate?.logYearInReviewDidTapShare(slideLoggingID: slideLoggingID)
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

    func markFirstSlideAsSeen() {
        if let dataController = try? WMFYearInReviewDataController() {
            dataController.hasSeenYiRIntroSlide = true
            badgeDelegate?.didSeeFirstSlide()
        }
    }
    
    public func handleInfo() {
        if let url = slides[currentSlide].infoURL {
            coordinatorDelegate?.handleYearInReviewAction(.info(url: url))
        }
    }
}

public struct YearInReviewSlideContent: SlideShowProtocol {
    public var infoURL: URL?
    public let imageName: String
    public let imageOverlay: String?
    public let textOverlay: String?
    public let title: String
    let informationBubbleText: String?
    public let subtitle: String
    public let loggingID: String
    public let hideDonateButton: Bool
    
    public init(imageName: String, imageOverlay: String? = nil, textOverlay: String? = nil, title: String, informationBubbleText: String?, subtitle: String, loggingID: String, infoURL: URL? = nil, hideDonateButton: Bool) {
        self.imageName = imageName
        self.imageOverlay = imageOverlay
        self.textOverlay = textOverlay
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
        self.loggingID = loggingID
        self.infoURL = infoURL
		self.hideDonateButton = hideDonateButton
    }
}


@objc public protocol YearInReviewBadgeDelegate: AnyObject {
    @objc func didSeeFirstSlide()
}
