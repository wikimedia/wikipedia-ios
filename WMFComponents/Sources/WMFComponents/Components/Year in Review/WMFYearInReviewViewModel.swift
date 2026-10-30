import Combine
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
    /// .riv and no slide logging. Its toolbar button shares the highlights.
    public static let endPageID = "yearInReviewEnd"
    /// The slide id reported for a tap on "Share highlights".
    static let endLoggingID = "end"

    public struct LocalizedStrings {
        public let wIconAccessibilityLabel: String
        public let closeButtonAccessibilityLabel: String
        public let moreButtonAccessibilityLabel: String
        public let shareButtonTitle: String
        public let shareHighlightsButtonTitle: String
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
            shareHighlightsButtonTitle: String,
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
            self.shareHighlightsButtonTitle = shareHighlightsButtonTitle
            self.donateButtonTitle = donateButtonTitle
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.aboutInsightsButtonTitle = aboutInsightsButtonTitle
            self.shareFeedbackButtonTitle = shareFeedbackButtonTitle
            self.slidePositionAccessibilityValue = slidePositionAccessibilityValue
        }
    }

    @Published public var slides: [WMFYearInReviewSlideViewModel]

    /// The slide that shows its answer in place. The answer has its own logging ID.
    private var answerShownSlideID: String?

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
            answerShownSlideID = nil
            logSlideAppearance()
        }
    }
    @Published public var isLoadingDonate: Bool = false

    /// The end screen, shown as the page after the last slide. The coordinator sets it. `nil` means there is no end screen.
    @Published public var endViewModel: WMFYearInReviewEndViewModel?

    /// What "Share highlights" on the end screen shares. The coordinator sets it. `nil` in the
    /// collective flow, which has no highlights.
    @Published public var highlights: WMFYearInReviewHighlights?

    /// The content style that each loaded slide reads from its .riv, by slide id.
    @Published private(set) var loadedContentStyles: [String: WMFYearInReviewSlideViewModel.ContentStyle] = [:]

    @Published public var topSafeAreaInset: CGFloat = 0

    /// Set by the end screen when its sky scrolled away from under the controls. Then the controls
    /// are light, because they sit on the dark page.
    @Published public var endUsesLightContent = false

    /// How far the end screen has come in while the pager moves between the last slide and the end
    /// screen: 0 on the last slide, 1 on the end screen. It is 0 on the other slides. It changes on
    /// each scroll step, so it is a subject, not `@Published`, and the pager does not render again.
    public let endPageReveal = CurrentValueSubject<CGFloat, Never>(0)

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

    /// The index in `pagerSlides`. The pager can rest on an answer that is no longer its own slide,
    /// for example after VoiceOver turns off. Then this is the index of the slide with that answer.
    public var currentSlideIndex: Int {
        let pagerSlides = pagerSlides
        // The end screen is not a slide. Count it as the last slide for the position.
        if isOnEnd {
            return max(pagerSlides.count - 1, 0)
        }
        guard let currentSlideID else { return 0 }
        return pagerSlides.firstIndex { $0.id == currentSlideID }
            ?? pagerSlides.firstIndex { $0.answer?.id == currentSlideID }
            ?? 0
    }

    /// `nil` on the end screen, so it has no share or donate button and logs no slide impression.
    public var currentSlide: WMFYearInReviewSlideViewModel? {
        let pagerSlides = pagerSlides
        guard !isOnEnd, pagerSlides.indices.contains(currentSlideIndex) else { return nil }
        return pagerSlides[currentSlideIndex]
    }

    private var currentLoggingID: String {
        guard let currentSlide else { return "" }
        if currentSlide.id == answerShownSlideID, let answer = currentSlide.answer {
            return answer.loggingID
        }
        return currentSlide.loggingID
    }

    /// The color of the controls above the current slide. The value that the .riv sets wins over the
    /// style of the slide view model. The end screen has a light top, so its controls are dark until
    /// the sky scrolls away from under them.
    public var currentContentColor: UIColor? {
        contentColor(onEnd: isOnEnd)
    }

    /// The color of the bar items. During the swipe between the last slide and the end screen, it
    /// changes halfway, not when the swipe ends.
    var barContentColor: UIColor? {
        let reveal = endPageReveal.value
        let isMoving = reveal > 0 && reveal < 1
        return contentColor(onEnd: isMoving ? reveal > 0.5 : isOnEnd)
    }

    private func contentColor(onEnd: Bool) -> UIColor? {
        if onEnd {
            return (endUsesLightContent ? WMFYearInReviewSlideViewModel.ContentStyle.light : .dark).color
        }
        guard let slide = isOnEnd ? pagerSlides.last : currentSlide else { return nil }
        return (loadedContentStyles[slide.id] ?? slide.contentStyle).color
    }

    /// Called on each scroll step of the pager. `position` is the page at the top, with a fraction.
    func pagerDidScroll(toPosition position: CGFloat) {
        let reveal = endViewModel == nil ? 0 : min(max(position - CGFloat(pagerSlides.count - 1), 0), 1)
        guard reveal != endPageReveal.value else { return }
        endPageReveal.send(reveal)
    }

    /// The color around the page and of the toolbar. It is the dark chrome color on every page,
    /// including the end screen, where only the toolbar shows it. The end screen covers the rest.
    public var currentChromeColor: UIColor {
        Self.chromeBackgroundColor
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
        pageIDs.count
    }

    /// The ids of the pages in the pager, in order: the pager slides, then the end screen if there is one.
    var pageIDs: [String] {
        pagerSlides.map(\.id) + (endViewModel == nil ? [] : [Self.endPageID])
    }

    /// The position of the current page. The end screen is the page after the last slide.
    public var currentPageIndex: Int {
        isOnEnd ? pagerSlides.count : currentSlideIndex
    }

    public var isLastSlide: Bool {
        return currentSlideIndex == max(pagerSlides.count - 1, 0)
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

    func tappedClose() {
        loggingDelegate?.logYearInReviewDidTapDone(slideLoggingID: currentLoggingID)
        coordinatorDelegate?.handleYearInReviewAction(.close)
    }

    /// A slide with its own donate button does not show the share button, so the donate button is
    /// the only action on the slide. On the end screen, the button shares the highlights, and only
    /// shows with enough of them.
    var showsShareButton: Bool {
        if isOnEnd {
            return highlights?.isShareable ?? false
        }
        return showsShareButton(on: currentSlide)
    }

    /// Matches 2025 behavior. A slide with its own donate button does not show the toolbar button too.
    var showsDonateButton: Bool {
        showsDonateButton(on: currentSlide)
    }

    /// The slide whose buttons are in the toolbar. On the end screen, it is the last slide. The end
    /// screen hides its buttons, and they fade in while the reader swipes back to it.
    var toolbarSlide: WMFYearInReviewSlideViewModel? {
        isOnEnd ? pagerSlides.last : currentSlide
    }

    var toolbarShowsShareButton: Bool {
        showsShareButton(on: toolbarSlide)
    }

    var toolbarShowsDonateButton: Bool {
        showsDonateButton(on: toolbarSlide)
    }

    /// "Share highlights" is the button of the end screen. It is in the toolbar on the last slide too,
    /// hidden, so it fades in while the end screen comes in. It needs enough highlights.
    var toolbarShowsShareHighlightsButton: Bool {
        endViewModel != nil && isLastSlide && (highlights?.isShareable ?? false)
    }

    private func showsShareButton(on slide: WMFYearInReviewSlideViewModel?) -> Bool {
        guard let slide else {
            return false
        }
        return slide.showsShareButton && !slide.showsPrimaryDonateButton
    }

    private func showsDonateButton(on slide: WMFYearInReviewSlideViewModel?) -> Bool {
        guard let slide,
              slide.showsDonateButton,
              !slide.showsPrimaryDonateButton else {
            return false
        }

        return !hidesDonate()
    }

    func tappedLearnMore() {
        coordinatorDelegate?.handleYearInReviewAction(.learnMore(slideLoggingID: currentLoggingID))
    }

    func tappedAboutInsights() {
        coordinatorDelegate?.handleYearInReviewAction(.aboutInsights(slideLoggingID: currentLoggingID))
    }

    func tappedShareFeedback() {
        coordinatorDelegate?.handleYearInReviewAction(.shareFeedback(slideLoggingID: currentLoggingID))
    }

    func tappedShare() {
        if isOnEnd {
            tappedShareHighlights()
            return
        }
        guard let slide = currentSlide else { return }
        loggingDelegate?.logYearInReviewDidTapShare(slideLoggingID: currentLoggingID)
        coordinatorDelegate?.handleYearInReviewAction(.share(slideID: slide.id))
    }

    func tappedShareHighlights() {
        guard highlights?.isShareable ?? false else { return }
        loggingDelegate?.logYearInReviewDidTapShare(slideLoggingID: Self.endLoggingID)
        coordinatorDelegate?.handleYearInReviewAction(.shareHighlights)
    }

    func tappedDonate(sourceRect: @escaping @MainActor () -> CGRect) {
        guard currentSlide != nil else { return }
        let slideLoggingID = currentLoggingID
        loggingDelegate?.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID)
        coordinatorDelegate?.handleYearInReviewAction(.donate(getSourceRect: sourceRect, slideLoggingID: slideLoggingID))
    }

    func answerDidShow(slideID: String) {
        guard slideID == currentSlide?.id, slideID != answerShownSlideID else { return }
        answerShownSlideID = slideID
        logSlideAppearance()
    }

    private func logSlideAppearance() {
        guard currentSlide != nil else { return }
        loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: currentLoggingID)
    }
}
