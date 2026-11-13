import Combine
import UIKit
import WMFData

@MainActor
public final class WMFYearInReviewViewModel: ObservableObject {

    public static let chromeBackgroundColor = UIColor(0x161616)

    /// Both bottom corners follow this.
    public static let slideCornerRadius = WMFCornerRadius.xxLarge

    public static let toolbarMinimumHeight: CGFloat = 64

    public static let progressBarEdgeInset: CGFloat = 2

    /// The space between the navigation bar and the progress bar.
    public static let progressBarTopGap = WMFSpacing.medium

    /// The id of the end screen page, which comes after the last slide. It is not a slide: it has no
    /// .riv, no slide impression, and no share button in the toolbar. It keeps the donate button of the
    /// slide chrome, and its own button shares the highlights.
    public static let endPageID = "yearInReviewEnd"

    /// The `page` name of the end screen in the instrumentation, the same as Android. The donate
    /// campaign ID is made from it.
    public static let endLoggingID = "end"

    public struct LocalizedStrings {
        public let closeButtonAccessibilityLabel: String
        public let moreButtonAccessibilityLabel: String
        public let shareButtonTitle: String
        public let shareHighlightsButtonTitle: String
        public let donateButtonTitle: String
        public let learnMoreButtonTitle: String
        public let aboutInsightsButtonTitle: String
        public let shareFeedbackButtonTitle: String
        /// Tells a VoiceOver reader how to change the slide. A one-finger swipe does not change it.
        public let slideAccessibilityHint: String
        /// On a slide with an answer, while VoiceOver runs. A double tap shows the answer.
        public let revealAnswerAccessibilityHint: String

        public init(
            closeButtonAccessibilityLabel: String,
            moreButtonAccessibilityLabel: String,
            shareButtonTitle: String,
            shareHighlightsButtonTitle: String,
            donateButtonTitle: String,
            learnMoreButtonTitle: String,
            aboutInsightsButtonTitle: String,
            shareFeedbackButtonTitle: String,
            slideAccessibilityHint: String,
            revealAnswerAccessibilityHint: String
        ) {
            self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
            self.moreButtonAccessibilityLabel = moreButtonAccessibilityLabel
            self.shareButtonTitle = shareButtonTitle
            self.shareHighlightsButtonTitle = shareHighlightsButtonTitle
            self.donateButtonTitle = donateButtonTitle
            self.learnMoreButtonTitle = learnMoreButtonTitle
            self.aboutInsightsButtonTitle = aboutInsightsButtonTitle
            self.shareFeedbackButtonTitle = shareFeedbackButtonTitle
            self.slideAccessibilityHint = slideAccessibilityHint
            self.revealAnswerAccessibilityHint = revealAnswerAccessibilityHint
        }
    }

    @Published public var slides: [WMFYearInReviewSlideViewModel]

    /// The slide that shows its answer in place. The answer has its own logging ID.
    private var answerShownSlideID: String?

    /// When true, the answer of a slide is the next slide in the pager. Nothing sets it now: with
    /// VoiceOver, a double tap shows the answer in place, the same as a tap on a card.
    @Published var showsAnswersAsSlides = false

    /// Whether the one-time swipe-up hint is on screen. `WMFYearInReviewHostingController` draws it
    /// over the whole screen, the bars included.
    @Published public private(set) var isShowingSwipeOnboarding = false

    /// The wait before the hint shows. Once set, it is never cleared, so the hint is scheduled at
    /// most once per visit.
    private(set) var swipeOnboardingTask: Task<Void, Never>?
    private let swipeOnboardingDelay: Duration
    /// Holds the seen flag. Without it, the hint never shows.
    private let swipeOnboardingDataController: WMFYearInReviewDataController?

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

    /// The page at the top of the pager, with a fraction. It is a subject for the same reason as
    /// `endPageReveal`. The progress bar moves with it during a swipe.
    let pagerPosition = CurrentValueSubject<CGFloat, Never>(0)

    public let localizedStrings: LocalizedStrings

    private weak var coordinatorDelegate: WMFYearInReviewCoordinating?
    private weak var loggingDelegate: WMFYearInReviewLoggingDelegate?

    /// True where donations are not accepted. Tests pass a fixed value.
    private let hidesDonate: () -> Bool

    /// - Parameters:
    ///   - hidesDonate: Without the data controller, the country check cannot run. Then the
    ///     donate button hides, so it never shows where donations are not accepted.
    ///   - swipeOnboardingDelay: How long the first slide plays before the swipe-up hint shows.
    public init(
        slides: [WMFYearInReviewSlideViewModel],
        localizedStrings: LocalizedStrings,
        coordinatorDelegate: WMFYearInReviewCoordinating?,
        loggingDelegate: WMFYearInReviewLoggingDelegate?,
        hidesDonate: @escaping () -> Bool = { (try? WMFYearInReviewDataController())?.shouldHideDonateButton() ?? true },
        swipeOnboardingDelay: Duration = .seconds(2),
        swipeOnboardingDataController: WMFYearInReviewDataController? = try? WMFYearInReviewDataController()
    ) {
        self.slides = slides
        self.currentSlideID = slides.first?.id
        self.localizedStrings = localizedStrings
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.hidesDonate = hidesDonate
        self.swipeOnboardingDelay = swipeOnboardingDelay
        self.swipeOnboardingDataController = swipeOnboardingDataController
    }

    deinit {
        swipeOnboardingTask?.cancel()
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

    /// `nil` on the end screen, so it has no share button and logs no slide impression.
    public var currentSlide: WMFYearInReviewSlideViewModel? {
        let pagerSlides = pagerSlides
        guard !isOnEnd, pagerSlides.indices.contains(currentSlideIndex) else { return nil }
        return pagerSlides[currentSlideIndex]
    }

    /// The current slide, or its answer after the answer replaced it in place.
    private var currentShownSlide: WMFYearInReviewSlideViewModel? {
        guard let currentSlide else { return nil }
        if currentSlide.id == answerShownSlideID, let answer = currentSlide.answer {
            return answer
        }
        return currentSlide
    }

    /// Empty on the end screen. Only the donate tap logs `endLoggingID` there, so the Done, Learn
    /// more, About insights and Share feedback data stay as before.
    private var currentLoggingID: String {
        currentShownSlide?.loggingID ?? ""
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
        if position != pagerPosition.value {
            pagerPosition.send(position)
        }
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

    var progressBarTopInset: CGFloat {
        topSafeAreaInset + Self.progressBarTopGap
    }

    public func onAppear() {
        logSlideAppearance()
    }

    // MARK: - Swipe onboarding

    /// Called when the slides are on screen. Shows the swipe-up hint after a short wait, once per
    /// device.
    ///
    /// - Returns: True when the hint is scheduled. The caller then reports the reader's first touch
    ///   through `dismissSwipeOnboarding()`.
    @discardableResult
    public func scheduleSwipeOnboardingIfNeeded() -> Bool {
        guard swipeOnboardingTask == nil,
              !showsAnswersAsSlides,
              let swipeOnboardingDataController,
              !swipeOnboardingDataController.hasSeenYiRSwipeOnboarding else {
            return false
        }
        let delay = swipeOnboardingDelay
        swipeOnboardingTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.isShowingSwipeOnboarding = true
        }
        return true
    }

    /// The reader's first touch. Hides the hint and marks it seen. A touch during the wait also
    /// marks it seen: the reader already knows how to move through the slides.
    public func dismissSwipeOnboarding() {
        swipeOnboardingTask?.cancel()
        isShowingSwipeOnboarding = false
        swipeOnboardingDataController?.hasSeenYiRSwipeOnboarding = true
    }

    func tappedClose() {
        loggingDelegate?.logYearInReviewDidTapDone(slideLoggingID: currentLoggingID)
        coordinatorDelegate?.handleYearInReviewAction(.close)
    }

    /// A slide with its own donate button does not show the share button, so the donate button is
    /// the only action on the slide.
    var showsShareButton: Bool {
        showsShareButton(on: currentSlide)
    }

    /// The end screen shows "Share highlights" only with enough highlights.
    var showsShareHighlightsButton: Bool {
        highlights?.isShareable ?? false
    }

    /// Matches 2025 behavior. A slide with its own donate button does not show the toolbar button too.
    var showsDonateButton: Bool {
        isOnEnd ? endShowsDonateButton : showsDonateButton(on: currentSlide)
    }

    /// The end screen keeps the donate button of the slide chrome, but not the share button
    /// (T438574). Android shows it there too.
    var endShowsDonateButton: Bool {
        endViewModel != nil && !hidesDonate()
    }

    /// The slide whose buttons are in the toolbar. On the end screen, it is the last slide. The end
    /// screen hides its share button, and it fades in while the reader swipes back to the last slide.
    var toolbarSlide: WMFYearInReviewSlideViewModel? {
        isOnEnd ? pagerSlides.last : currentSlide
    }

    var toolbarShowsShareButton: Bool {
        showsShareButton(on: toolbarSlide)
    }

    /// On the last slide, the toolbar also holds the donate button of the end screen, so that it
    /// fades in during the swipe instead of appearing when the swipe ends.
    var toolbarShowsDonateButton: Bool {
        showsDonateButton(on: toolbarSlide) || (toolbarIsOnLastPage && endShowsDonateButton)
    }

    /// The donate button of the last slide stays during the swipe to the end screen. If only the end
    /// screen has one, for example after "You matter" with its own donate button, it fades in.
    var toolbarDonateButtonFadesIn: Bool {
        !showsDonateButton(on: toolbarSlide)
    }

    /// How far the toolbar buttons have faded toward the end screen. While the pager is between the
    /// last slide and the end screen, it is `endPageReveal`. Elsewhere it comes from the current page,
    /// because the end screen can become current without a scroll step that sets the reveal to 1, for
    /// example after a VoiceOver page scroll or a pager rebuild.
    ///
    /// It must not guess "at rest" from the position alone. The current page changes only when the
    /// pager is within 1 pt of a page and the finger is up (`WMFYearInReviewPageObserver`), so in the
    /// last frames of a swipe the current page is still the one the reader left. A position check
    /// would show that page's buttons for those frames, and the donate button would flicker.
    var toolbarEndReveal: CGFloat {
        let position = pagerPosition.value
        let lastSlidePosition = CGFloat(pagerSlides.count - 1)
        let isBetweenLastSlideAndEnd = position > lastSlidePosition && position < lastSlidePosition + 1
        guard endViewModel != nil, isBetweenLastSlideAndEnd else { return isOnEnd ? 1 : 0 }
        return endPageReveal.value
    }

    /// The last slide or the end screen.
    private var toolbarIsOnLastPage: Bool {
        isOnEnd || (currentSlide != nil && isLastSlide)
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
        guard let slide = currentShownSlide else { return }
        loggingDelegate?.logYearInReviewDidTapShare(slideLoggingID: currentLoggingID)
        coordinatorDelegate?.handleYearInReviewAction(.share(slideID: slide.id))
    }

    func tappedShareHighlights(sourceRect: @escaping @MainActor @Sendable () -> CGRect) {
        guard showsShareHighlightsButton else { return }
        loggingDelegate?.logYearInReviewDidTapShareHighlights()
        coordinatorDelegate?.handleYearInReviewAction(.shareHighlights(getSourceRect: sourceRect))
    }

    func tappedDonate(sourceRect: @escaping @MainActor () -> CGRect) {
        guard currentSlide != nil || isOnEnd else { return }
        let slideLoggingID = isOnEnd ? Self.endLoggingID : currentLoggingID
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
