import UIKit
import WMFData

@MainActor
public final class WMFYearInReviewViewModel: ObservableObject {

    public static let chromeBackgroundColor = UIColor(0x161616)

    /// Both bottom corners follow this.
    public static let slideCornerRadius = WMFCornerRadius.xxLarge

    public static let toolbarMinimumHeight: CGFloat = 64

    public static let progressBarEdgeInset = WMFSpacing.medium

    /// The space between the navigation bar and the progress bar.
    public static let progressBarTopGap = WMFSpacing.medium

    /// The id of the end screen page, which comes after the last slide. It is not a slide: it has no
    /// .riv, no logging, and no share or donate button.
    public static let endPageID = "yearInReviewEnd"

    public struct LocalizedStrings {
        public let wIconAccessibilityLabel: String
        public let closeButtonAccessibilityLabel: String
        public let moreButtonAccessibilityLabel: String
        public let shareButtonTitle: String
        public let donateButtonTitle: String
        public let learnMoreButtonTitle: String
        public let aboutInsightsButtonTitle: String
        public let shareFeedbackButtonTitle: String
        public let slidePositionAccessibilityValue: (Int, Int) -> String

        public init(
            wIconAccessibilityLabel: String,
            closeButtonAccessibilityLabel: String,
            moreButtonAccessibilityLabel: String,
            shareButtonTitle: String,
            donateButtonTitle: String,
            learnMoreButtonTitle: String,
            aboutInsightsButtonTitle: String,
            shareFeedbackButtonTitle: String,
            slidePositionAccessibilityValue: @escaping (Int, Int) -> String
        ) {
            self.wIconAccessibilityLabel = wIconAccessibilityLabel
            self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
            self.moreButtonAccessibilityLabel = moreButtonAccessibilityLabel
            self.shareButtonTitle = shareButtonTitle
            self.donateButtonTitle = donateButtonTitle
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.aboutInsightsButtonTitle = aboutInsightsButtonTitle
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

    /// The end screen, shown as the page after the last slide. The coordinator sets it. `nil` means there is no end screen.
    @Published public var endViewModel: WMFYearInReviewEndViewModel?

    /// The content style that each loaded slide reads from its .riv, by slide id.
    @Published private(set) var loadedContentStyles: [String: WMFYearInReviewSlideViewModel.ContentStyle] = [:]

    @Published public var topSafeAreaInset: CGFloat = 0

    public let localizedStrings: LocalizedStrings

    private weak var coordinatorDelegate: WMFYearInReviewCoordinating?
    private weak var loggingDelegate: WMFYearInReviewLoggingDelegate?

    /// True where donations are not accepted. Tests pass a fixed value.
    private let hidesDonate: () -> Bool

    /// - Parameter hidesDonate: Without the data controller, the country check cannot run. Then the
    ///   donate button hides, so it never shows where donations are not accepted.
    public init(
        slides: [WMFYearInReviewSlideViewModel],
        localizedStrings: LocalizedStrings,
        coordinatorDelegate: WMFYearInReviewCoordinating?,
        loggingDelegate: WMFYearInReviewLoggingDelegate?,
        hidesDonate: @escaping () -> Bool = { (try? WMFYearInReviewDataController())?.shouldHideDonateButton() ?? true }
    ) {
        self.slides = slides
        self.currentSlideID = slides.first?.id
        self.localizedStrings = localizedStrings
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.hidesDonate = hidesDonate
    }

    /// Whether the reader is on the end screen, not on a slide.
    public var isOnEnd: Bool {
        currentSlideID == Self.endPageID
    }

    public var currentSlideIndex: Int {
        // The end screen is not a slide. Count it as the last slide for the position.
        if isOnEnd {
            return max(slides.count - 1, 0)
        }
        guard let currentSlideID,
              let index = slides.firstIndex(where: { $0.id == currentSlideID }) else { return 0 }
        return index
    }

    /// `nil` on the end screen, so it has no share or donate button and logs no slide impression.
    public var currentSlide: WMFYearInReviewSlideViewModel? {
        guard !isOnEnd, slides.indices.contains(currentSlideIndex) else { return nil }
        return slides[currentSlideIndex]
    }

    /// The color of the controls above the current slide. The value that the .riv sets wins over the
    /// style of the slide view model. The end screen has a light top, so its controls are always dark.
    public var currentContentColor: UIColor? {
        if isOnEnd {
            return WMFYearInReviewSlideViewModel.ContentStyle.dark.color
        }
        guard let currentSlide else { return nil }
        return (loadedContentStyles[currentSlide.id] ?? currentSlide.contentStyle).color
    }

    /// Puts `slide` in the place of the slide with `id`, for example the contributor slide after a
    /// donation. If the reader is on that slide, they stay on it.
    public func replaceSlide(id: String, with slide: WMFYearInReviewSlideViewModel) {
        guard let index = slides.firstIndex(where: { $0.id == id }) else { return }
        let wasCurrent = currentSlideID == id
        slides[index] = slide
        loadedContentStyles[id] = nil
        if wasCurrent {
            currentSlideID = slide.id
        }
    }

    /// Records the style that a slide read from its .riv after it loaded.
    func slideDidLoad(lightContent: Bool, slideID: String) {
        loadedContentStyles[slideID] = lightContent ? .light : .dark
    }

    /// The number of pages: the slides, plus the end screen if there is one. The progress bar counts pages.
    public var pageCount: Int {
        slides.count + (endViewModel == nil ? 0 : 1)
    }

    /// The position of the current page. The end screen is the page after the last slide.
    public var currentPageIndex: Int {
        isOnEnd ? slides.count : currentSlideIndex
    }

    public var isLastSlide: Bool {
        return currentSlideIndex == max(slides.count - 1, 0)
    }

    var slidePositionAccessibilityValue: String {
        localizedStrings.slidePositionAccessibilityValue(currentPageIndex + 1, pageCount)
    }

    var progressBarTopInset: CGFloat {
        topSafeAreaInset + Self.progressBarTopGap
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

    /// A slide with its own donate button does not show the share button, so the donate button is
    /// the only action on the slide.
    var showsShareButton: Bool {
        guard let currentSlide else {
            return false
        }
        return currentSlide.showsShareButton && !currentSlide.showsPrimaryDonateButton
    }

    /// Matches 2025 behavior. A slide with its own donate button does not show the toolbar button too.
    var showsDonateButton: Bool {
        guard let currentSlide,
              currentSlide.showsDonateButton,
              !currentSlide.showsPrimaryDonateButton else {
            return false
        }

        return !hidesDonate()
    }

    func tappedLearnMore() {
        coordinatorDelegate?.handleYearInReviewAction(.learnMore(slideLoggingID: currentSlide?.loggingID ?? ""))
    }

    func tappedAboutInsights() {
        coordinatorDelegate?.handleYearInReviewAction(.aboutInsights(slideLoggingID: currentSlide?.loggingID ?? ""))
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
