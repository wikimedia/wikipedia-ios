import UIKit

@MainActor
public protocol WMFYearInReviewAnnouncementDelegate: AnyObject {
    func yearInReviewAnnouncementDidTapExplore()
    func yearInReviewAnnouncementDidTapClose()
    func yearInReviewAnnouncementDidTapLearnMore()
    func yearInReviewAnnouncementDidTapAboutInsights()
    func yearInReviewAnnouncementDidTapShareFeedback()
}

@MainActor
public final class WMFYearInReviewAnnouncementViewModel: ObservableObject {

    public struct LocalizedStrings {
        /// VoiceOver reads this for the Rive artwork. The headline is drawn inside the artwork,
        /// so this should contain the headline text.
        public let animationAccessibilityLabel: String
        /// Drawn inside the artwork. VoiceOver reads it after the headline.
        public let body: String
        public let exploreButtonTitle: String
        public let wIconAccessibilityLabel: String
        public let closeButtonAccessibilityLabel: String
        public let moreButtonAccessibilityLabel: String
        public let learnMoreButtonTitle: String
        public let aboutInsightsButtonTitle: String
        public let shareFeedbackButtonTitle: String

        public init(
            animationAccessibilityLabel: String,
            body: String,
            exploreButtonTitle: String,
            wIconAccessibilityLabel: String,
            closeButtonAccessibilityLabel: String,
            moreButtonAccessibilityLabel: String,
            learnMoreButtonTitle: String,
            aboutInsightsButtonTitle: String,
            shareFeedbackButtonTitle: String
        ) {
            self.animationAccessibilityLabel = animationAccessibilityLabel
            self.body = body
            self.exploreButtonTitle = exploreButtonTitle
            self.wIconAccessibilityLabel = wIconAccessibilityLabel
            self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
            self.moreButtonAccessibilityLabel = moreButtonAccessibilityLabel
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.aboutInsightsButtonTitle = aboutInsightsButtonTitle
            self.shareFeedbackButtonTitle = shareFeedbackButtonTitle
        }
    }

    public let animation: WMFRiveAnimation?
    public let riveText: [WMFRiveText: String]
    public let riveNumbers: [WMFRiveNumber: Double]
    public let localizedStrings: LocalizedStrings

    /// Which color the navigation bar items use above the artwork.
    public let contentStyle: WMFYearInReviewSlideViewModel.ContentStyle

    private weak var delegate: WMFYearInReviewAnnouncementDelegate?

    public init(
        animation: WMFRiveAnimation?,
        riveText: [WMFRiveText: String] = [:],
        riveNumbers: [WMFRiveNumber: Double] = [:],
        localizedStrings: LocalizedStrings,
        contentStyle: WMFYearInReviewSlideViewModel.ContentStyle = .light,
        delegate: WMFYearInReviewAnnouncementDelegate?
    ) {
        self.animation = animation
        self.riveText = riveText
        self.riveNumbers = riveNumbers
        self.localizedStrings = localizedStrings
        self.contentStyle = contentStyle
        self.delegate = delegate
    }

    /// Same rule as `WMFYearInReviewSlideViewModel.contentColor`.
    var contentColor: UIColor {
        contentStyle == .light ? WMFColor.white : WMFColor.gray700
    }

    func tappedExplore() {
        delegate?.yearInReviewAnnouncementDidTapExplore()
    }

    func tappedClose() {
        delegate?.yearInReviewAnnouncementDidTapClose()
    }

    func tappedLearnMore() {
        delegate?.yearInReviewAnnouncementDidTapLearnMore()
    }

    func tappedAboutInsights() {
        delegate?.yearInReviewAnnouncementDidTapAboutInsights()
    }

    func tappedShareFeedback() {
        delegate?.yearInReviewAnnouncementDidTapShareFeedback()
    }
}
