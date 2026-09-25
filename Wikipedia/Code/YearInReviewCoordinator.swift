import UIKit
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

    // MARK: - Presentation

    private func presentYearInReview() {
        let viewModel = WMFYearInReviewViewModel(
            slides: slideFactory.makeSlides(),
            localizedStrings: slideFactory.makeLocalizedStrings(),
            coordinatorDelegate: self,
            loggingDelegate: self
        )

        self.viewModel = viewModel

        let hostingController = WMFYearInReviewHostingController(viewModel: viewModel)
        let presentedNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)
        navigationController.present(presentedNavigationController, animated: true)
    }

    private func presentFeatureAnnouncement() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            let userDataState = (try? await dataController.fetchUserDataState()) ?? .lowData
            let readingDayCount = (try? await dataController.fetchReadingDayCount()) ?? 0

            // Something may have been presented while the data loaded.
            guard navigationController.presentedViewController == nil else { return }

            let viewModel = WMFYearInReviewAnnouncementViewModel(
                // TODO: Add the announcement .riv file and its WMFRiveAnimation here.
                animation: nil,
                localizedStrings: announcementLocalizedStrings(userDataState: userDataState, readingDayCount: readingDayCount),
                delegate: self
            )

            let hostingController = WMFYearInReviewAnnouncementHostingController(viewModel: viewModel)
            hostingController.modalPresentationStyle = .pageSheet
            // Swiping down would skip the close action and its toast, so only the close button dismisses.
            hostingController.isModalInPresentation = true
            navigationController.present(hostingController, animated: true)

            // Marked here, when it is actually on screen, so a force quit before any interaction
            // does not earn a second showing, and an early exit above does not use it up.
            dataController.hasPresentedYiRFeatureAnnouncement = true
        }
    }

    private func announcementLocalizedStrings(userDataState: WMFYearInReviewDataController.YiRUserDataState, readingDayCount: Int) -> WMFYearInReviewAnnouncementViewModel.LocalizedStrings {
        let body: String
        switch userDataState {
        case .dataRich:
            let format = WMFLocalizedString("year-in-review-2026-announcement-personalized-body", value: "Thanks for spending {{PLURAL:%1$d|%1$d day|%1$d days}} on your trusty Wikipedia App in 2026.", comment: "Body text of the Year in Review announcement for readers with enough reading data. %1$d is replaced with the number of days the reader read articles in the app.")
            body = String.localizedStringWithFormat(format, readingDayCount)
        case .lowData:
            // TODO: Replace with the collective copy once design provides it, as a WMFLocalizedString.
            body = "Collective announcement copy TBD"
        }

        return WMFYearInReviewAnnouncementViewModel.LocalizedStrings(
            animationAccessibilityLabel: WMFLocalizedString("year-in-review-2026-announcement-headline", value: "Your Wikipedia Year in Review is here", comment: "Headline of the Year in Review announcement. It is drawn inside the artwork, so VoiceOver reads this text."),
            body: body,
            exploreButtonTitle: WMFLocalizedString("year-in-review-2026-announcement-explore", value: "Explore", comment: "Title of the button on the Year in Review announcement that opens Year in Review."),
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            infoButtonAccessibilityHint: announcementInfoTitle,
            infoTitle: announcementInfoTitle,
            infoBody: WMFLocalizedString("year-in-review-2026-announcement-info-body", value: "Reading insights are calculated using locally stored data on your device.", comment: "Body of the info card on the Year in Review announcement, which explains how reading data is used."),
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            gotItButtonTitle: CommonStrings.gotItButtonTitle
        )
    }

    private var announcementInfoTitle: String {
        WMFLocalizedString("year-in-review-2026-announcement-info-title", value: "Your reading history is kept protected", comment: "Title of the info card on the Year in Review announcement, shown when the reader taps the info icon.")
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

    /// The FAQ page is translated per app language, so the URL is built rather than hardcoded.
    private var featureFAQURL: URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }

        return WMFProject.mediawiki.translatedHelpURL(
            pathComponents: ["Wikimedia Apps", "Team", "Wikipedia Year in Review", "Frequently Asked Questions"],
            section: "Frequently asked questions",
            language: appLanguage
        )
    }

    private func showLearnMore() {
        guard let presentedViewController = navigationController.presentedViewController,
              let featureFAQURL else {
            return
        }

        let config = SinglePageWebViewController.StandardConfig(url: featureFAQURL, useSimpleNavigationBar: true)
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
            showLearnMore()
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
        // TODO: Logged-out readers see the log in prompt here first.
        guard let presentedViewController = navigationController.presentedViewController else {
            presentYearInReview()
            return
        }

        presentedViewController.dismiss(animated: true) { [weak self] in
            self?.presentYearInReview()
        }
    }

    func yearInReviewAnnouncementDidTapClose() {
        navigationController.presentedViewController?.dismiss(animated: true) {
            WMFToastManager.sharedInstance.showToast(CommonStrings.youCanAccessYIRInActivity, sticky: false, dismissPreviousToasts: true)
        }
    }

    func yearInReviewAnnouncementDidTapLearnMore() {
        showLearnMore()
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
