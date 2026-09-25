import UIKit

@MainActor
public protocol WMFYearInReviewAnnouncementDelegate: AnyObject {
    func yearInReviewAnnouncementDidTapExplore()
    func yearInReviewAnnouncementDidTapClose()
    func yearInReviewAnnouncementDidTapLearnMore()
}

@MainActor
public final class WMFYearInReviewAnnouncementViewModel: ObservableObject {

    public struct LocalizedStrings {
        /// VoiceOver reads this for the Rive artwork. The headline is drawn inside the artwork,
        /// so this should contain the headline text.
        public let animationAccessibilityLabel: String
        /// The copy under the artwork. The app builds it, so the personalized and the collective
        /// versions only differ in the string passed in.
        public let body: String
        public let exploreButtonTitle: String
        public let closeButtonAccessibilityLabel: String
        public let infoButtonAccessibilityHint: String
        public let infoTitle: String
        public let infoBody: String
        public let learnMoreButtonTitle: String
        public let gotItButtonTitle: String

        public init(
            animationAccessibilityLabel: String,
            body: String,
            exploreButtonTitle: String,
            closeButtonAccessibilityLabel: String,
            infoButtonAccessibilityHint: String,
            infoTitle: String,
            infoBody: String,
            learnMoreButtonTitle: String,
            gotItButtonTitle: String
        ) {
            self.animationAccessibilityLabel = animationAccessibilityLabel
            self.body = body
            self.exploreButtonTitle = exploreButtonTitle
            self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
            self.infoButtonAccessibilityHint = infoButtonAccessibilityHint
            self.infoTitle = infoTitle
            self.infoBody = infoBody
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.gotItButtonTitle = gotItButtonTitle
        }
    }

    public let animation: WMFRiveAnimation?
    public let riveText: [WMFRiveText: String]
    public let riveNumbers: [WMFRiveNumber: Double]
    public let localizedStrings: LocalizedStrings

    /// Which color the close button uses above the artwork. Same rule as the slides.
    public let contentStyle: WMFYearInReviewSlideViewModel.ContentStyle

    @Published public private(set) var isShowingInfo = false

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

    var closeButtonColor: UIColor {
        contentStyle == .light ? WMFColor.whiteAlpha20 : WMFColor.gray700
    }

    func tappedExplore() {
        delegate?.yearInReviewAnnouncementDidTapExplore()
    }

    func tappedClose() {
        delegate?.yearInReviewAnnouncementDidTapClose()
    }

    func tappedInfo() {
        isShowingInfo = true
    }

    func tappedGotIt() {
        isShowingInfo = false
    }

    func tappedLearnMore() {
        isShowingInfo = false
        delegate?.yearInReviewAnnouncementDidTapLearnMore()
    }
}
