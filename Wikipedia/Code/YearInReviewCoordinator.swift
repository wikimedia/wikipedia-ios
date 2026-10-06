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
    /// TODO: add when data ticket is available
    private var introSlideLoggingID: String = ""

    /// The data state the announcement was built with. It picks the slides opened from the
    /// announcement and the log in prompt copy.
    private var announcementUserDataState: WMFYearInReviewDataController.YiRUserDataState = .lowData

    private weak var viewModel: WMFYearInReviewViewModel?

    /// Makes the slides and the strings. This type only injects them and keeps the delegates.
    private let slideFactory = YearInReviewSlideViewModelFactory()

    /// Makes the announcement screen and the text of the log in prompt that follows it.
    private let announcementFactory = YearInReviewAnnouncementViewModelFactory()

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
        presentYearInReview()
        return true
    }

    /// Loads the announcement data and shows the announcement. Returns true only when it is on screen.
    /// The caller decides whether a pop-up is allowed now, and what comes next when this returns false.
    @MainActor
    func presentFeatureAnnouncement(introSlideLoggingID: String) async -> Bool {
        guard dataController.shouldShowYearInReviewFeatureAnnouncement() else {
            return false
        }

        self.introSlideLoggingID = introSlideLoggingID

        let userDataState = (try? await dataController.fetchUserDataState()) ?? .lowData
        let readingDayCount = (try? await dataController.fetchReadingDayCount()) ?? 0

        // Something may have been presented while the data loaded.
        guard navigationController.presentedViewController == nil else {
            return false
        }

        announcementUserDataState = userDataState
        let viewModel = announcementFactory.makeViewModel(
            userDataState: userDataState,
            readingDayCount: readingDayCount,
            delegate: self
        )

        let hostingController = WMFYearInReviewAnnouncementHostingController(viewModel: viewModel)
        let announcementNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .pageSheet)
        announcementNavigationController.isModalInPresentation = true
        navigationController.present(announcementNavigationController, animated: true)

        // Marked here, when it is on screen, so an early exit above does not use it up.
        dataController.hasPresentedYiRFeatureAnnouncement = true
        return true
    }

    // MARK: - Presentation

    /// `userDataState` is nil for the profile entry point, which does not pick slides here.
    ///
    /// TODO: Decide which slides to show when the report is built, once each slide knows whether it
    /// has data. `userDataState` is a temporary proxy for that (see `dataRichDistinctArticleThreshold`
    /// in `WMFYearInReviewDataController`). Remove this parameter when that work lands.
    private func presentYearInReview(userDataState: WMFYearInReviewDataController.YiRUserDataState? = nil) {
        let viewModel = WMFYearInReviewViewModel(
            slides: slideFactory.makeSlides(for: userDataState),
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

    // MARK: - Announcement log in prompt

    /// Asks logged-out readers to log in first. Logging in or creating an account opens the slides
    /// for `userDataStateAfterLogin`. Continuing without logging in always opens the low data slides.
    private func presentAnnouncementLoginPrompt(userDataStateAfterLogin: WMFYearInReviewDataController.YiRUserDataState) {
        guard let announcement = navigationController.presentedViewController else {
            presentYearInReview(userDataState: .lowData)
            return
        }

        let copy = announcementFactory.makeLoginPromptCopy(userDataState: announcementUserDataState)

        let alert = UIAlertController(title: copy.title, message: copy.message, preferredStyle: .alert)

        let loginAction = UIAlertAction(title: CommonStrings.joinLoginTitle, style: .default) { [weak self] _ in
            self?.dismissAnnouncement {
                self?.startAnnouncementLogin(userDataStateAfterLogin: userDataStateAfterLogin)
            }
        }

        let continueAction = UIAlertAction(title: CommonStrings.continueWithoutLoggingIn, style: .default) { [weak self] _ in
            self?.dismissAnnouncement {
                self?.presentYearInReview(userDataState: .lowData)
            }
        }

        alert.addAction(loginAction)
        alert.addAction(continueAction)
        alert.preferredAction = loginAction
        alert.view.tintColor = theme.colors.link

        announcement.present(alert, animated: true)
    }

    private func startAnnouncementLogin(userDataStateAfterLogin: WMFYearInReviewDataController.YiRUserDataState) {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController, theme: theme, loggingCategory: .yir)

        // The log in screen calls this before it dismisses itself, so wait for that to finish.
        loginCoordinator.loginSuccessCompletion = { [weak self] in
            Task { @MainActor [weak self] in
                self?.presentYearInReviewAfterCurrentDismissal(userDataState: userDataStateAfterLogin)
            }
        }

        // Account creation leaves its screen up, so dismiss it here first.
        loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
            guard let self else { return }
            guard let accountCreation = navigationController.presentedViewController else {
                presentYearInReview(userDataState: userDataStateAfterLogin)
                return
            }
            accountCreation.dismiss(animated: true) { [weak self] in
                self?.presentYearInReview(userDataState: userDataStateAfterLogin)
            }
        }

        loginCoordinator.start()
    }

    /// Presents the slides once any dismissal in progress is done.
    private func presentYearInReviewAfterCurrentDismissal(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        guard let transitionCoordinator = navigationController.transitionCoordinator else {
            presentYearInReview(userDataState: userDataState)
            return
        }

        transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.presentYearInReview(userDataState: userDataState)
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
        let userDataState = announcementUserDataState

        guard dataStore.authenticationManager.authStateIsPermanent else {
            presentAnnouncementLoginPrompt(userDataStateAfterLogin: userDataState)
            return
        }

        dismissAnnouncement { [weak self] in
            self?.presentYearInReview(userDataState: userDataState)
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
