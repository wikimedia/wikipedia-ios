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

    /// True while VoiceOver runs. `WMFYearInReviewView` sets it. A VoiceOver reader cannot tap an
    /// answer in the .riv, so the answer of a slide is the next slide in the pager.
    @Published var showsAnswersAsSlides = false

    /// The slides in the pager, in order. Without VoiceOver, a slide and its answer take one position.
    var pagerSlides: [WMFYearInReviewSlideViewModel] {
        guard showsAnswersAsSlides else { return slides }
        return slides.flatMap { slide in
            [slide] + (slide.answer.map { [$0] } ?? [])
        }
    }

    /// The slide that the pager rests on. `WMFYearInReviewView` sets it from the scroll view. Setting
    /// it does not scroll.
    @Published public var currentSlideID: String? {
        didSet {
            guard currentSlideID != oldValue else { return }
            logSlideAppearance()
        }
    }
    @Published public var isLoadingDonate: Bool = false

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

    /// The index in `pagerSlides`. The pager can rest on an answer that is no longer its own slide,
    /// for example after VoiceOver turns off. Then this is the index of the slide with that answer.
    public var currentSlideIndex: Int {
        guard let currentSlideID else { return 0 }
        let pagerSlides = pagerSlides
        return pagerSlides.firstIndex { $0.id == currentSlideID }
            ?? pagerSlides.firstIndex { $0.answer?.id == currentSlideID }
            ?? 0
    }

    public var currentSlide: WMFYearInReviewSlideViewModel? {
        let pagerSlides = pagerSlides
        guard pagerSlides.indices.contains(currentSlideIndex) else { return nil }
        return pagerSlides[currentSlideIndex]
    }

    /// The color of the controls above the current slide. The value that the .riv sets wins over the
    /// style of the slide view model.
    public var currentContentColor: UIColor? {
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

    public var isLastSlide: Bool {
        return currentSlideIndex == max(pagerSlides.count - 1, 0)
    }

    var slidePositionAccessibilityValue: String {
        localizedStrings.slidePositionAccessibilityValue(currentSlideIndex + 1, pagerSlides.count)
    }

    var progressBarTopInset: CGFloat {
        topSafeAreaInset + Self.progressBarTopGap
    }

    public func onAppear() {
        logSlideAppearance()
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
