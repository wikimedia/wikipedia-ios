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
    var hasSeenTwoSlides: Bool = false
    public let isUserAuth: Bool

    @Published public var isLoading: Bool = false

    public init(isFirstSlide: Bool = true, localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent], shareLink: String, hashtag: String, hasPersonalizedDonateSlide: Bool, coordinatorDelegate: YearInReviewCoordinatorDelegate?, loggingDelegate: WMFYearInReviewLoggingDelegate, badgeDelegate: YearInReviewBadgeDelegate?, isUserAuth: Bool) {
        self.isFirstSlide = isFirstSlide
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.shareLink = shareLink
        self.hasPersonalizedDonateSlide = hasPersonalizedDonateSlide
        self.hashtag = hashtag
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.badgeDelegate = badgeDelegate
        self.isUserAuth = isUserAuth
    }

    public func getStarted() {
        isFirstSlide = false
    }
    
    public func nextSlide() {
        if isLastSlide {
            coordinatorDelegate?.handleYearInReviewAction(.dismiss(hasSeenTwoSlides: true))
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
        
        public let wIconAccessibilityLabel: String
        public let wmfLogoImageAccessibilityLabel: String
        
        public let personalizedExploreAccessibilityLabel: String
        public let personalizedYouReadAccessibilityLabel: String
        public let personalizedUserEditsAccessibilityLabel: String
        public let personalizedDonationThankYouAccessibilityLabel: String
        public let personalizedSavedArticlesAccessibilityLabel: String
        public let personalizedWeekdayAccessibilityLabel: String
        public let personalizedYourEditsViewsAccessibilityLabel: String
        
        public let collectiveExploreAccessibilityLabel: String
        public let collectiveLanguagesAccessibilityLabel: String
        public let collectiveArticleViewsAccessibilityLabel: String
        public let collectiveSavedArticlesAccessibilityLabel: String
        public let collectiveAmountEditsAccessibilityLabel: String
        public let englishEditsAccessibilityLabel: String
        public let collectiveEditsPerMinuteAccessibilityLabel: String
        public let collectiveZeroAdsAccessibilityLabel: String
        
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, firstSlideTitle: String, firstSlideSubtitle: String, firstSlideCTA: String, firstSlideLearnMore: String, shareText: String, wIconAccessibilityLabel: String, wmfLogoImageAccessibilityLabel: String, personalizedExploreAccessibilityLabel: String, personalizedYouReadAccessibilityLabel: String, personalizedUserEditsAccessibilityLabel: String, personalizedDonationThankYouAccessibilityLabel: String, personalizedSavedArticlesAccessibilityLabel: String, personalizedWeekdayAccessibilityLabel: String, personalizedYourEditsViewsAccessibilityLabel: String, collectiveExploreAccessibilityLabel: String, collectiveLanguagesAccessibilityLabel: String, collectiveArticleViewsAccessibilityLabel: String, collectiveSavedArticlesAccessibilityLabel: String, collectiveAmountEditsAccessibilityLabel: String, englishEditsAccessibilityLabel: String, collectiveEditsPerMinuteAccessibilityLabel: String, collectiveZeroAdsAccessibilityLabel: String) {
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
            self.wIconAccessibilityLabel = wIconAccessibilityLabel
            self.wmfLogoImageAccessibilityLabel = wmfLogoImageAccessibilityLabel
            self.personalizedExploreAccessibilityLabel = personalizedExploreAccessibilityLabel
            self.personalizedYouReadAccessibilityLabel = personalizedYouReadAccessibilityLabel
            self.personalizedUserEditsAccessibilityLabel = personalizedUserEditsAccessibilityLabel
            self.personalizedDonationThankYouAccessibilityLabel = personalizedDonationThankYouAccessibilityLabel
            self.personalizedSavedArticlesAccessibilityLabel = personalizedSavedArticlesAccessibilityLabel
            self.personalizedWeekdayAccessibilityLabel = personalizedWeekdayAccessibilityLabel
            self.personalizedYourEditsViewsAccessibilityLabel = personalizedYourEditsViewsAccessibilityLabel
            self.collectiveExploreAccessibilityLabel = collectiveExploreAccessibilityLabel
            self.collectiveLanguagesAccessibilityLabel = collectiveLanguagesAccessibilityLabel
            self.collectiveArticleViewsAccessibilityLabel = collectiveArticleViewsAccessibilityLabel
            self.collectiveSavedArticlesAccessibilityLabel = collectiveSavedArticlesAccessibilityLabel
            self.collectiveAmountEditsAccessibilityLabel = collectiveAmountEditsAccessibilityLabel
            self.englishEditsAccessibilityLabel = englishEditsAccessibilityLabel
            self.collectiveEditsPerMinuteAccessibilityLabel = collectiveEditsPerMinuteAccessibilityLabel
            self.collectiveZeroAdsAccessibilityLabel = collectiveZeroAdsAccessibilityLabel
        }
    }

    func handleShare(for slide: Int) {
        let view = WMFYearInReviewShareableSlideView(imageName: slides[slide].gifName, altText: slides[slide].altText, slideTitle: slides[slide].title, slideSubtitle: slides[slide].subtitle, hashtag: hashtag, isAttributedString: slides[slide].isSubtitleAttributedString ?? false)
        let shareView = view.snapshot()
        coordinatorDelegate?.handleYearInReviewAction(.share(image: shareView))
    }
    
    func handleDone() {
        coordinatorDelegate?.handleYearInReviewAction(.dismiss(hasSeenTwoSlides: hasSeenTwoSlides))
    }
    
    func handleDonate(sourceRect: CGRect) {
        coordinatorDelegate?.handleYearInReviewAction(.donate(sourceRect: sourceRect))
    }
    
    func handleLearnMore(url: URL) {
        var shouldShowDonate = false
        if slides.count - 1 == currentSlide && !hasPersonalizedDonateSlide {
            shouldShowDonate = true
        }

        // Always verify for regions we cannot ask for donations
        shouldShowDonate = !shouldHideDonateButtonForCertainRegions()

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
        if isFirstSlide {
            return isUserAuth ? "start_c" : "start"
        }
        
        return slides[currentSlide].loggingID
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
            badgeDelegate?.updateYIRBadgeVisibility()
        }
    }

    public func handleInfo() {
        if let url = slides[currentSlide].infoURL {
            coordinatorDelegate?.handleYearInReviewAction(.info(url: url))
        }
    }

    public func shouldHideDonateButtonForCertainRegions() -> Bool {
        guard let dataController = try? WMFYearInReviewDataController() else {
            return false
        }
        return dataController.shouldHideDonateButton()
    }
}

public struct YearInReviewSlideContent: SlideShowProtocol {

    public var infoURL: URL?
    public let gifName: String
    public let altText: String
    public let title: String
    let informationBubbleText: String?
    public let subtitle: String
    public let isSubtitleAttributedString: Bool?
    public let loggingID: String
    public let hideDonateButton: Bool
    
    public init(gifName: String, altText: String, title: String, informationBubbleText: String?, subtitle: String, isSubtitleAttributedString: Bool? = false, loggingID: String, infoURL: URL? = nil, hideDonateButton: Bool) {
        self.altText = altText
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
        self.loggingID = loggingID
        self.infoURL = infoURL
		self.hideDonateButton = hideDonateButton
        self.gifName = gifName
        self.isSubtitleAttributedString = isSubtitleAttributedString
    }
}

@objc public protocol YearInReviewBadgeDelegate: AnyObject {
    @objc func updateYIRBadgeVisibility()
}
