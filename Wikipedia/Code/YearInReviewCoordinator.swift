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

    private weak var viewModel: WMFYearInReviewViewModel?

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
        let viewModel = WMFYearInReviewViewModel(
            slides: Self.placeholderSlides(),
            localizedStrings: Self.localizedStrings(),
            coordinatorDelegate: self,
            loggingDelegate: self
        )

        self.viewModel = viewModel

        let hostingController = WMFYearInReviewHostingController(viewModel: viewModel)
        let presentedNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)
        navigationController.present(presentedNavigationController, animated: true)

        return true
    }

    func setupForFeatureAnnouncement(introSlideLoggingID: String) {
        self.introSlideLoggingID = introSlideLoggingID
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

    // MARK: - Strings and slides

    private static func localizedStrings() -> WMFYearInReviewViewModel.LocalizedStrings {
        WMFYearInReviewViewModel.LocalizedStrings(
            wIconAccessibilityLabel: "Wikipedia",
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: "More",
            shareButtonTitle: CommonStrings.shortShareTitle,
            donateButtonTitle: CommonStrings.donateTitle,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle,
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    private static func placeholderSlides() -> [WMFYearInReviewSlideViewModel] {
        // TEMPORARY: three slides driven from the one sample .riv, to prove injection.
        let frame1 = "frame1"
        let frame2 = "frame2"
        let stateMachine = "insightFrame-stateMachine"

        let cream = UIColor(red: 0.98, green: 0.976, blue: 0.961, alpha: 1)
        let mint = UIColor(red: 0.839, green: 0.937, blue: 0.898, alpha: 1)
        let tan = UIColor(red: 0.929, green: 0.890, blue: 0.784, alpha: 1)

        return [
            WMFYearInReviewSlideViewModel(
                id: "readCount",
                loggingID: "readCount",
                animation: WMFRiveAnimation(resourceName: riveResourceName, artboardName: frame1, stateMachineName: stateMachine),
                text: [
                    WMFRiveText(path: "headline1"): "YOU READ",
                    WMFRiveText(path: "headline2"): "350 ARTICLES",
                    WMFRiveText(path: "bodyCopy"): "That puts you in the top 5% of readers on English Wikipedia this year.",
                    WMFRiveText(path: "readDays"): "47"
                ],
                backgroundColor: cream,
                localizedStrings: .init(accessibilityLabel: "You read 350 articles across 47 days."),
                showsShareButton: false
            ),
            WMFYearInReviewSlideViewModel(
                id: "streak",
                loggingID: "streak",
                animation: WMFRiveAnimation(resourceName: riveResourceName, artboardName: frame2, stateMachineName: stateMachine),
                text: [
                    WMFRiveText(path: "headline1"): "YOUR LONGEST",
                    WMFRiveText(path: "headline2"): "STREAK",
                    WMFRiveText(path: "bodyCopy"): "Thirty-one days in a row, from 4 to 14 March.",
                    WMFRiveText(path: "streakNumber"): "31"
                ],
                backgroundColor: mint,
                localizedStrings: .init(accessibilityLabel: "Your longest streak was 31 days.")
            ),
            WMFYearInReviewSlideViewModel(
                id: "minutesRead",
                loggingID: "minutesRead",
                animation: WMFRiveAnimation(resourceName: riveResourceName, artboardName: frame1, stateMachineName: stateMachine),
                text: [
                    WMFRiveText(path: "headline1"): "924 MINUTES",
                    WMFRiveText(path: "headline2"): "OF READING",
                    WMFRiveText(path: "bodyCopy"): "Mostly on Wednesday evenings, going by your reading history.",
                    WMFRiveText(path: "readDays"): "128"
                ],
                backgroundColor: tan,
                localizedStrings: .init(accessibilityLabel: "You read for 924 minutes.")
            )
        ]
    }

    // TEMPORARY: the sample export, replaced per slide when design delivers the real files.
    private static let riveResourceName = "autolayout_multiple_instances_test"
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
