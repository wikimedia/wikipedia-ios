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
        // TEMPORARY: mock slides driven from the one sample .riv. The sentences are hardcoded
        // stand-ins for WMFLocalizedString, including the Arabic and Chinese ones, so the split
        // can be seen working in a right-to-left script and in one with no spaces.
        let frame1 = "frame1"
        let frame2 = "frame2"
        let stateMachine = "insightFrame-stateMachine"

        let headline1 = WMFRiveText(path: "headline1")
        let headline2 = WMFRiveText(path: "headline2")
        let bodyCopy = WMFRiveText(path: "bodyCopy")
        let readDays = WMFRiveText(path: "readDays")
        let streakNumber = WMFRiveText(path: "streakNumber")

        let cream = UIColor(red: 0.98, green: 0.976, blue: 0.961, alpha: 1)
        let mint = UIColor(red: 0.839, green: 0.937, blue: 0.898, alpha: 1)
        let tan = UIColor(red: 0.929, green: 0.890, blue: 0.784, alpha: 1)
        let sand = UIColor(red: 0.941, green: 0.925, blue: 0.882, alpha: 1)
        let sky = UIColor(red: 0.886, green: 0.929, blue: 0.960, alpha: 1)

        /// One sentence, one variable, spread across the three runs that draw it.
        func slide(
            id: String,
            artboard: String,
            sentence: String,
            value: String,
            numberPath: WMFRiveText,
            body: String,
            backgroundColor: UIColor,
            accessibilityLabel: String,
            showsShareButton: Bool = true
        ) -> WMFYearInReviewSlideViewModel {
            var text = WMFRiveSentence(
                format: sentence,
                value: value,
                leading: headline1,
                middle: numberPath,
                trailing: headline2
            ).text
            text[bodyCopy] = body

            return WMFYearInReviewSlideViewModel(
                id: id,
                loggingID: id,
                animation: WMFRiveAnimation(resourceName: riveResourceName, artboardName: artboard, stateMachineName: stateMachine),
                text: text,
                backgroundColor: backgroundColor,
                localizedStrings: .init(accessibilityLabel: accessibilityLabel),
                showsShareButton: showsShareButton
            )
        }

        return [
            slide(
                id: "readCount",
                artboard: frame1,
                sentence: "In 2026, you read Wikipedia on %1$@ days.",
                value: "47",
                numberPath: readDays,
                body: "That puts you in the top 5% of readers on English Wikipedia this year.",
                backgroundColor: cream,
                accessibilityLabel: "In 2026, you read Wikipedia on 47 days.",
                showsShareButton: false
            ),
            slide(
                id: "streak",
                artboard: frame2,
                sentence: "Your longest streak was %1$@ days in a row.",
                value: "31",
                numberPath: streakNumber,
                body: "From 4 to 14 March.",
                backgroundColor: mint,
                accessibilityLabel: "Your longest streak was 31 days in a row."
            ),
            slide(
                id: "minutesRead",
                artboard: frame1,
                sentence: "You spent %1$@ minutes reading this year.",
                value: "924",
                numberPath: readDays,
                body: "Mostly on Wednesday evenings, going by your reading history.",
                backgroundColor: tan,
                accessibilityLabel: "You spent 924 minutes reading this year."
            ),
            // The placeholder sits late in the sentence and the script runs right to left.
            slide(
                id: "arabicSample",
                artboard: frame1,
                sentence: "في عام 2026، ستطالع ويكيبيديا على مدار %1$@ يوماً.",
                value: "47",
                numberPath: readDays,
                body: "نص تجريبي للتحقق من عرض النص العربي داخل الرسوم المتحركة.",
                backgroundColor: sand,
                accessibilityLabel: "Arabic sample slide."
            ),
            // The placeholder sits mid-sentence and the script has no spaces to trim.
            slide(
                id: "chineseSample",
                artboard: frame1,
                sentence: "2026年，你在%1$@天里阅读了维基百科。",
                value: "47",
                numberPath: readDays,
                body: "这是一段用于检查中文排版的示例文字。",
                backgroundColor: sky,
                accessibilityLabel: "Chinese sample slide."
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
