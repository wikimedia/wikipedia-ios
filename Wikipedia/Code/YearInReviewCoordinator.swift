import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Presents the Year in Review flow. Slide content is drawn by Rive; the app supplies the
/// navigation bar, the toolbar and the injected text.
final class YearInReviewCoordinator: NSObject, Coordinator {

    var theme: Theme
    var navigationController: UINavigationController

    let dataStore: MWKDataStore
    let dataController: WMFYearInReviewDataController

    weak var badgeDelegate: YearInReviewBadgeDelegate?

    /// The slide id reported for actions taken on the first slide. An announcement entry point
    /// overrides it so the funnel records where the flow was opened from.
    private var introSlideLoggingID: String = "profile"

    /// Set by `setupForFeatureAnnouncement`. The next `start()` shows the announcement screen
    /// instead of the slides, then clears this. Explore shares this coordinator with the profile
    /// entry point, so the flag must not stay on after the announcement.
    private var isFeatureAnnouncement = false

    /// True while the announcement's data loads. Home can ask twice in a row (on appear and on
    /// becoming active), so a second request is ignored until the first one finishes.
    private var isPreparingFeatureAnnouncement = false

    /// Which slides to show. Picked from the reader's data and whether they log in from the
    /// announcement.
    enum Flow {
        case personalized
        case collective
    }

    /// The data state the announcement was built with. Explore uses it to pick the flow and the log
    /// in prompt copy.
    private var announcementUserDataState: WMFYearInReviewDataController.YiRUserDataState = .lowData

    private weak var viewModel: WMFYearInReviewViewModel?

    /// Makes the slides and the strings. This type only injects them and keeps the delegates.
    private let slideFactory = YearInReviewSlideViewModelFactory()

    /// DonateCoordinator drives a multi-step flow of its own, so it has to outlive this call.
    private var donateCoordinator: DonateCoordinator?

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, dataController: WMFYearInReviewDataController) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.dataController = dataController
        super.init()
    }

    @discardableResult
    func start() -> Bool {
        if isFeatureAnnouncement {
            isFeatureAnnouncement = false
            presentFeatureAnnouncement()
        } else {
            presentYearInReview()
        }

        return true
    }

    func setupForFeatureAnnouncement(introSlideLoggingID: String) {
        self.introSlideLoggingID = introSlideLoggingID
        isFeatureAnnouncement = true
    }

    /// Shows the announcement if the reader should see it now. Explore and Home use this, so both
    /// follow the same rules. Calls `onNotShown` when nothing is presented, so the caller can move on
    /// to its next modal.
    ///
    /// Fundraising goes first through `shouldShowYearInReviewFeatureAnnouncement()`: if the campaign
    /// banner showed this session, the announcement waits for the next app open.
    func presentFeatureAnnouncementIfNeeded(from viewController: UIViewController, introSlideLoggingID: String, onShown: @escaping () -> Void = {}, onNotShown: @escaping () -> Void = {}) {
        guard canPresentFeatureAnnouncement(from: viewController) else {
            onNotShown()
            return
        }

        onShown()
        setupForFeatureAnnouncement(introSlideLoggingID: introSlideLoggingID)
        start()
    }

    private func canPresentFeatureAnnouncement(from viewController: UIViewController) -> Bool {
        guard !isPreparingFeatureAnnouncement else {
            return false
        }

        if UIDevice.current.userInterfaceIdiom == .pad && navigationController.navigationBar.isHidden {
            return false
        }

        // No announcement during a session that was started by a deep link.
#if !TEST
        if let sceneDelegate = viewController.view.window?.windowScene?.delegate as? SceneDelegate,
           sceneDelegate.didOpenAppFromExternalLink {
            return false
        }
#endif

        guard dataController.shouldShowYearInReviewFeatureAnnouncement() else {
            return false
        }

        // Explore and Home share a navigation controller, so check both for something on screen.
        guard viewController.presentedViewController == nil,
              navigationController.presentedViewController == nil else {
            return false
        }

        guard viewController.isViewLoaded, viewController.view.window != nil else {
            return false
        }

        return true
    }

    // MARK: - Presentation

    /// `flow` is nil for the profile entry point, which does not pick a flow here.
    private func presentYearInReview(flow: Flow? = nil) {
        let viewModel = WMFYearInReviewViewModel(
            slides: slideFactory.makeSlides(for: flow),
            localizedStrings: slideFactory.makeLocalizedStrings(),
            coordinatorDelegate: self,
            loggingDelegate: self
        )

        self.viewModel = viewModel

        let hostingController = WMFYearInReviewHostingController(viewModel: viewModel)
        let presentedNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)
        navigationController.present(presentedNavigationController, animated: true)

        // The reader has seen Year in Review, so the announcement no longer needs to show.
        dataController.hasSeenYiRIntroSlide = true
    }

    private func presentFeatureAnnouncement() {
        // Article calls `start()` directly, so this check is here as well as in
        // `canPresentFeatureAnnouncement`.
        guard !isPreparingFeatureAnnouncement else { return }
        isPreparingFeatureAnnouncement = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isPreparingFeatureAnnouncement = false }

            // The developer settings toggle decides the state when it is set. See fetchUserDataState().
            let userDataState = (try? await dataController.fetchUserDataState()) ?? .lowData
            let readingDayCount = (try? await dataController.fetchReadingDayCount()) ?? 0
            announcementUserDataState = userDataState

            // Something may have been presented while the data loaded.
            guard navigationController.presentedViewController == nil else { return }

            let localizedStrings = announcementLocalizedStrings(userDataState: userDataState, readingDayCount: readingDayCount)

            let viewModel = WMFYearInReviewAnnouncementViewModel(
                animation: announcementAnimation,
                riveText: [
                    CoverTextPath.title: localizedStrings.animationAccessibilityLabel,
                    CoverTextPath.body: localizedStrings.body
                ],
                localizedStrings: localizedStrings,
                delegate: self
            )

            // In a navigation controller so it gets the same close button and more menu as the slides.
            let hostingController = WMFYearInReviewAnnouncementHostingController(viewModel: viewModel)
            let announcementNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .pageSheet)
            // Swiping down would skip the close action and its toast, so only the close button dismisses.
            announcementNavigationController.isModalInPresentation = true
            navigationController.present(announcementNavigationController, animated: true)

            // Marked here, when it is actually on screen, so a force quit before any interaction
            // does not earn a second showing, and an early exit above does not use it up.
            dataController.hasPresentedYiRFeatureAnnouncement = true
        }
    }

    private func announcementLocalizedStrings(userDataState: WMFYearInReviewDataController.YiRUserDataState, readingDayCount: Int) -> WMFYearInReviewAnnouncementViewModel.LocalizedStrings {
        let headline: String
        let body: String
        switch userDataState {
        case .dataRich:
            headline = WMFLocalizedString("year-in-review-2026-announcement-headline", value: "Your Wikipedia Year in Review is here", comment: "Headline of the Year in Review announcement for readers with enough reading data. It is drawn inside the artwork, so VoiceOver reads this text.")
            let format = WMFLocalizedString("year-in-review-2026-announcement-personalized-body", value: "Thanks for spending {{PLURAL:%1$d|%1$d day|%1$d days}} on your trusty Wikipedia App in 2026.", comment: "Body text of the Year in Review announcement for readers with enough reading data. %1$d is replaced with the number of days the reader read articles in the app.")
            body = String.localizedStringWithFormat(format, readingDayCount)
        case .lowData:
            headline = collectiveHeadline
            body = collectiveBody
        }

        return WMFYearInReviewAnnouncementViewModel.LocalizedStrings(
            animationAccessibilityLabel: headline,
            body: body,
            exploreButtonTitle: WMFLocalizedString("year-in-review-2026-announcement-explore", value: "Explore", comment: "Title of the button on the Year in Review announcement that opens Year in Review."),
            wIconAccessibilityLabel: CommonStrings.plainWikipediaName,
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: CommonStrings.moreButton,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            aboutInsightsButtonTitle: YearInReviewSlideViewModelFactory.aboutInsightsButtonTitle,
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle
        )
    }

    /// Used by the collective announcement and the collective log in prompt.
    private var collectiveHeadline: String {
        WMFLocalizedString("year-in-review-2026-announcement-collective-headline", value: "Our Year in Review is here", comment: "Headline of the Year in Review announcement for readers without enough reading data for a personalized Year in Review, and title of the log in prompt shown to them. On the announcement it is drawn inside the artwork, so VoiceOver reads this text.")
    }

    /// Used by the collective announcement and the collective log in prompt.
    private var collectiveBody: String {
        WMFLocalizedString("year-in-review-2026-announcement-collective-body", value: "There wasn't enough activity to generate your own Year in Review this time, but you can still explore what the world discovered together.", comment: "Body text of the Year in Review announcement for readers without enough reading data for a personalized Year in Review, and message of the log in prompt shown to them.")
    }

    /// The announcement uses the cover artboard of the templates file.
    private let announcementAnimation = WMFRiveAnimation(
        resourceName: "all_templates",
        artboardName: "cover",
        stateMachineName: "cover-statemachine"
    )

    /// Text fields on the cover's `DataTemplate` view model. `headline` and `data` are not used.
    private enum CoverTextPath {
        static let title = WMFRiveText(path: "coverTitle")
        static let body = WMFRiveText(path: "bodyCopy")
    }

    // MARK: - Announcement log in prompt

    /// Asks logged-out readers to log in first. Logging in or creating an account opens
    /// `flowAfterLogin`. Continuing without logging in always opens the collective flow.
    private func presentAnnouncementLoginPrompt(flowAfterLogin: Flow) {
        guard let announcement = navigationController.presentedViewController else {
            presentYearInReview(flow: .collective)
            return
        }

        let title: String
        let message: String
        switch announcementUserDataState {
        case .dataRich:
            title = WMFLocalizedString("year-in-review-2026-announcement-login-personalized-title", value: "Your Year in Review is best with an account", comment: "Title of the prompt shown to logged-out readers with enough reading data after they tap Explore on the Year in Review announcement.")
            message = WMFLocalizedString("year-in-review-2026-announcement-login-personalized-message", value: "Log in to see your top topics, articles, longest rabbit hole, and more. You can still see collective insights without logging in.", comment: "Message of the prompt shown to logged-out readers with enough reading data after they tap Explore on the Year in Review announcement.")
        case .lowData:
            title = collectiveHeadline
            message = collectiveBody
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let loginAction = UIAlertAction(title: CommonStrings.joinLoginTitle, style: .default) { [weak self] _ in
            self?.dismissAnnouncement {
                self?.startAnnouncementLogin(flowAfterLogin: flowAfterLogin)
            }
        }

        let continueAction = UIAlertAction(title: CommonStrings.continueWithoutLoggingIn, style: .default) { [weak self] _ in
            self?.dismissAnnouncement {
                self?.presentYearInReview(flow: .collective)
            }
        }

        alert.addAction(loginAction)
        alert.addAction(continueAction)
        alert.preferredAction = loginAction
        alert.view.tintColor = theme.colors.link

        announcement.present(alert, animated: true)
    }

    private func startAnnouncementLogin(flowAfterLogin: Flow) {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController, theme: theme, loggingCategory: .yir)

        // The log in screen calls this before it dismisses itself, so wait for that to finish.
        loginCoordinator.loginSuccessCompletion = { [weak self] in
            DispatchQueue.main.async {
                self?.presentYearInReviewAfterCurrentDismissal(flow: flowAfterLogin)
            }
        }

        // Account creation leaves its screen up, so dismiss it here first.
        loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
            guard let self else { return }
            guard let accountCreation = navigationController.presentedViewController else {
                presentYearInReview(flow: flowAfterLogin)
                return
            }
            accountCreation.dismiss(animated: true) { [weak self] in
                self?.presentYearInReview(flow: flowAfterLogin)
            }
        }

        loginCoordinator.start()
    }

    /// Presents the slides once any dismissal in progress is done.
    private func presentYearInReviewAfterCurrentDismissal(flow: Flow) {
        guard let transitionCoordinator = navigationController.transitionCoordinator else {
            presentYearInReview(flow: flow)
            return
        }

        transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.presentYearInReview(flow: flow)
        }
    }

    private func dismissAnnouncement(completion: @escaping () -> Void) {
        guard let announcement = navigationController.presentedViewController else {
            completion()
            return
        }

        announcement.dismiss(animated: true, completion: completion)
    }

    // MARK: - Actions

    private func donate(getSourceRect: @escaping @MainActor () -> CGRect, slideLoggingID: String) {
        let donateCoordinator = DonateCoordinator(
            navigationController: navigationController,
            source: .yearInReview(slideLoggingID: slideLoggingID),
            dataStore: dataStore,
            theme: theme,
            navigationStyle: .present,
            setLoadingBlock: { [weak self] loading in
                MainActor.assumeIsolated {
                    self?.viewModel?.isLoadingDonate = loading
                }
            },
            getDonateButtonGlobalRect: {
                MainActor.assumeIsolated { getSourceRect() }
            }
        )

        self.donateCoordinator = donateCoordinator
        donateCoordinator.start()
    }

    /// The pages are translated per app language, so the URLs are built rather than hardcoded.
    private func yearInReviewHelpURL(pathComponents: [String], section: String?) -> URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }

        return WMFProject.mediawiki.translatedHelpURL(
            pathComponents: ["Wikimedia Apps", "Team", "Wikipedia Year in Review"] + pathComponents,
            section: section,
            language: appLanguage
        )
    }

    /// "Learn more" in the more menu opens the project page.
    private func showProjectPage() {
        showHelpPage(url: yearInReviewHelpURL(pathComponents: [], section: nil))
    }

    /// "About your insights" in the more menu opens the FAQ.
    private func showAboutInsights() {
        showHelpPage(url: yearInReviewHelpURL(pathComponents: ["Frequently Asked Questions"], section: nil))
    }

    private func showHelpPage(url: URL?) {
        guard let presentedViewController = navigationController.presentedViewController,
              let url else {
            return
        }

        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNavigationController = WMFComponentNavigationController(rootViewController: webViewController, modalPresentationStyle: .formSheet)
        presentedViewController.present(webNavigationController, animated: true)
    }

    private func shareFeedback() {
        let address = "ios-support@wikimedia.org"
        let subject = WMFLocalizedString("year-in-review-2026-feedback-email-subject", value: "Year in Review Feedback", comment: "Subject line of the pre-filled feedback email for the Year in Review feature.")
        let firstLine = WMFLocalizedString("year-in-review-2026-feedback-email-first-line", value: "I have feedback about Year in Review:", comment: "Opening line of the pre-filled feedback email body for the Year in Review feature.")
        let body = [
            firstLine,
            CommonStrings.issueReportEmailBodyDescribeProblem,
            CommonStrings.issueReportEmailBodyBehavior,
            CommonStrings.issueReportEmailBodyProposedSolution,
            CommonStrings.issueReportEmailBodyScreenshotsOrLinks
        ].joined(separator: "\n\n")

        let mailto = "mailto:\(address)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let encodedMailto = mailto,
              let mailtoURL = URL(string: encodedMailto),
              UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFToastManager.sharedInstance.showToast(CommonStrings.noEmailClient, sticky: false, dismissPreviousToasts: false)
            return
        }

        UIApplication.shared.open(mailtoURL)
    }

}

// MARK: - WMFYearInReviewCoordinating

extension YearInReviewCoordinator: WMFYearInReviewCoordinating {
    func handleYearInReviewAction(_ action: WMFYearInReviewAction) {
        switch action {
        case .close:
            navigationController.presentedViewController?.dismiss(animated: true)
        case .learnMore:
            showProjectPage()
        case .aboutInsights:
            showAboutInsights()
        case .shareFeedback:
            shareFeedback()
        case .share:
            break
        case .donate(let getSourceRect, let slideLoggingID):
            donate(getSourceRect: getSourceRect, slideLoggingID: slideLoggingID)
        }
    }
}

// MARK: - WMFYearInReviewAnnouncementDelegate

extension YearInReviewCoordinator: WMFYearInReviewAnnouncementDelegate {

    func yearInReviewAnnouncementDidTapExplore() {
        let flowForLoggedInReader: Flow = announcementUserDataState == .dataRich ? .personalized : .collective

        guard dataStore.authenticationManager.authStateIsPermanent else {
            presentAnnouncementLoginPrompt(flowAfterLogin: flowForLoggedInReader)
            return
        }

        dismissAnnouncement { [weak self] in
            self?.presentYearInReview(flow: flowForLoggedInReader)
        }
    }

    func yearInReviewAnnouncementDidTapClose() {
        navigationController.presentedViewController?.dismiss(animated: true) {
            WMFToastManager.sharedInstance.showToast(CommonStrings.youCanAccessYIRInActivity, sticky: false, dismissPreviousToasts: true)
        }
    }

    func yearInReviewAnnouncementDidTapLearnMore() {
        showProjectPage()
    }

    func yearInReviewAnnouncementDidTapAboutInsights() {
        showAboutInsights()
    }

    func yearInReviewAnnouncementDidTapShareFeedback() {
        shareFeedback()
    }
}

// MARK: - WMFYearInReviewLoggingDelegate

extension YearInReviewCoordinator: WMFYearInReviewLoggingDelegate {

    func logYearInReviewIntroDidTapLearnMore() {
        DonateFunnel.shared.logYearInReviewDidTapIntroLearnMore(slideLoggingID: introSlideLoggingID)
    }

    func logYearInReviewSlideDidAppear(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewSlideImpression(slideLoggingID: slideLoggingID)
    }

    func logYearInReviewDidTapDone(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapDone(slideLoggingID: slideLoggingID)
    }

    func logYearInReviewDidTapNext(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapNext(slideLoggingID: slideLoggingID)
    }

    func logYearInReviewDidTapDonate(slideLoggingID: String) {
        guard let metricsID = DonateCoordinator.metricsID(for: .yearInReview(slideLoggingID: slideLoggingID), languageCode: dataStore.languageLinkController.appLanguage?.languageCode) else {
            return
        }
        DonateFunnel.shared.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID, metricsID: metricsID)
    }

    func logYearInReviewDidTapShare(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapShare(slideLoggingID: slideLoggingID)
    }
}
