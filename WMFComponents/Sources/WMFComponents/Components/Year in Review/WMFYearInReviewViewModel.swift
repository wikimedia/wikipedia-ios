import UIKit

@MainActor
public final class WMFYearInReviewViewModel: ObservableObject {

    public static let chromeBackgroundColor = UIColor(0x161616)

    /// Design could not read the value off the Figma frame, so this is a judgement call.
    /// Change it here and both bottom corners follow.
    public static let slideCornerRadius: CGFloat = 24

    public static let toolbarMinimumHeight: CGFloat = 64

    public struct LocalizedStrings {
        public let wIconAccessibilityLabel: String
        public let closeButtonAccessibilityLabel: String
        public let moreButtonAccessibilityLabel: String
        public let shareButtonTitle: String
        public let donateButtonTitle: String
        public let learnMoreButtonTitle: String
        public let shareFeedbackButtonTitle: String
        public let slidePositionAccessibilityValue: (Int, Int) -> String

        public init(
            wIconAccessibilityLabel: String,
            closeButtonAccessibilityLabel: String,
            moreButtonAccessibilityLabel: String,
            shareButtonTitle: String,
            donateButtonTitle: String,
            learnMoreButtonTitle: String,
            shareFeedbackButtonTitle: String,
            slidePositionAccessibilityValue: @escaping (Int, Int) -> String
        ) {
            self.wIconAccessibilityLabel = wIconAccessibilityLabel
            self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
            self.moreButtonAccessibilityLabel = moreButtonAccessibilityLabel
            self.shareButtonTitle = shareButtonTitle
            self.donateButtonTitle = donateButtonTitle
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.shareFeedbackButtonTitle = shareFeedbackButtonTitle
            self.slidePositionAccessibilityValue = slidePositionAccessibilityValue
        }
    }

    @Published public var slides: [WMFYearInReviewSlideViewModel]

    /// Bound to `.scrollPosition(id:)`. The slide id is the source of truth, not an index:
    /// `.scrollPosition` resolves by identity, and an index binding does not survive a
    /// LazyVStack recycling its rows.
    @Published public var currentSlideID: String? {
        didSet {
            guard currentSlideID != oldValue else { return }
            logSlideAppearance()
        }
    }
    @Published public var isLoadingDonate: Bool = false

    public let localizedStrings: LocalizedStrings

    private weak var coordinatorDelegate: WMFYearInReviewCoordinating?
    private weak var loggingDelegate: WMFYearInReviewLoggingDelegate?

    public init(
        slides: [WMFYearInReviewSlideViewModel],
        localizedStrings: LocalizedStrings,
        coordinatorDelegate: WMFYearInReviewCoordinating?,
        loggingDelegate: WMFYearInReviewLoggingDelegate?
    ) {
        self.slides = slides
        self.currentSlideID = slides.first?.id
        self.localizedStrings = localizedStrings
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
    }

    public var currentSlideIndex: Int {
        guard let currentSlideID,
              let index = slides.firstIndex(where: { $0.id == currentSlideID }) else { return 0 }
        return index
    }

    public var currentSlide: WMFYearInReviewSlideViewModel? {
        guard slides.indices.contains(currentSlideIndex) else { return nil }
        return slides[currentSlideIndex]
    }

    public var isLastSlide: Bool {
        return currentSlideIndex == max(slides.count - 1, 0)
    }

    var slidePositionAccessibilityValue: String {
        localizedStrings.slidePositionAccessibilityValue(currentSlideIndex + 1, slides.count)
    }

    public func onAppear() {
        logSlideAppearance()
    }

    func tappedNext() {
        guard !isLastSlide else { return }
        loggingDelegate?.logYearInReviewDidTapNext(slideLoggingID: currentSlide?.loggingID ?? "")
        currentSlideID = slides[currentSlideIndex + 1].id
    }

    func tappedClose() {
        loggingDelegate?.logYearInReviewDidTapDone(slideLoggingID: currentSlide?.loggingID ?? "")
        coordinatorDelegate?.handleYearInReviewAction(.close)
    }

    func tappedLearnMore() {
        coordinatorDelegate?.handleYearInReviewAction(.learnMore(slideLoggingID: currentSlide?.loggingID ?? ""))
    }

    func tappedShareFeedback() {
        coordinatorDelegate?.handleYearInReviewAction(.shareFeedback(slideLoggingID: currentSlide?.loggingID ?? ""))
    }

    func tappedShare() {
        guard let slide = currentSlide else { return }
        loggingDelegate?.logYearInReviewDidTapShare(slideLoggingID: slide.loggingID)
        coordinatorDelegate?.handleYearInReviewAction(.share(slideID: slide.id))
    }

    func tappedDonate(sourceRect: @escaping @MainActor () -> CGRect) {
        guard let slide = currentSlide else { return }
        loggingDelegate?.logYearInReviewDidTapDonate(slideLoggingID: slide.loggingID)
        coordinatorDelegate?.handleYearInReviewAction(.donate(getSourceRect: sourceRect, slideLoggingID: slide.loggingID))
    }

    private func logSlideAppearance() {
        guard let slide = currentSlide else { return }
        loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: slide.loggingID)
    }
}
