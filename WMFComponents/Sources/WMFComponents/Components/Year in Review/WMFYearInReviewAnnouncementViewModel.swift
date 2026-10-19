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

    public let animation: WMFRiveAnimation
    public let riveText: [WMFRiveText: String]
    public let riveNumbers: [WMFRiveNumber: Double]
    public let localizedStrings: LocalizedStrings

    /// A boolean the artwork sets for the contrast of the controls above it, the same as on the
    /// slides. When the artwork loads, its value replaces `contentStyle`.
    public let lightContentFlag: WMFRiveBool?

    /// Makes long translations smaller so they stay inside the artwork, the same as on the slides.
    public let textFits: [WMFRiveTextFit]

    /// Which color the navigation bar items use above the artwork. The value passed in shows only
    /// until the artwork loads and reports `lightContentFlag`.
    @Published public private(set) var contentStyle: WMFYearInReviewSlideViewModel.ContentStyle

    private weak var delegate: WMFYearInReviewAnnouncementDelegate?

    public init(
        animation: WMFRiveAnimation,
        riveText: [WMFRiveText: String] = [:],
        riveNumbers: [WMFRiveNumber: Double] = [:],
        localizedStrings: LocalizedStrings,
        contentStyle: WMFYearInReviewSlideViewModel.ContentStyle = .light,
        lightContentFlag: WMFRiveBool? = nil,
        textFits: [WMFRiveTextFit] = [],
        delegate: WMFYearInReviewAnnouncementDelegate?
    ) {
        self.animation = animation
        self.riveText = riveText
        self.riveNumbers = riveNumbers
        self.localizedStrings = localizedStrings
        self.contentStyle = contentStyle
        self.lightContentFlag = lightContentFlag
        self.textFits = textFits
        self.delegate = delegate
    }

    var contentColor: UIColor {
        contentStyle.color
    }

    /// Called with the value of `lightContentFlag` after the artwork loads.
    func didReadLightContentFlag(_ isLight: Bool) {
        contentStyle = isLight ? .light : .dark
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
