import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Presents the Year in Review flow. Slide content is drawn by Rive; the app supplies the
/// navigation bar, the toolbar and the injected text.
final class YearInReviewCoordinator: NSObject, Coordinator {

    /// Fills the Year in Review report for the target year. The data controller checks the remote
    /// config, the active dates, the Settings toggle and the country, and returns `nil` when one of
    /// them stops the population.
    ///
    /// - Parameter regenerate: deletes the report first, so every slide is built again from the
    ///   current data, frozen slides too. Only the developer settings use it.
    @discardableResult
    static func populateReport(dataStore: MWKDataStore, regenerate: Bool = false) async throws -> WMFYearInReviewReport? {
        guard let appLanguage = dataStore.languageLinkController.appLanguage,
              let countryCode = Locale.current.region?.identifier else {
            return nil
        }

        let project = WMFProject.wikipedia(WMFLanguage(languageCode: appLanguage.languageCode, languageVariantCode: appLanguage.languageVariantCode))
        let permanentUser = dataStore.authenticationManager.permanentUser(siteURL: appLanguage.siteURL)
        let dataController = try WMFYearInReviewDataController()

        if regenerate {
            try await dataController.deleteYearInReviewReport(year: WMFYearInReviewDataController.targetYear)
        }

        return try await dataController.populateYearInReviewReportData(
            for: WMFYearInReviewDataController.targetYear,
            countryCode: countryCode,
            primaryAppLanguageProject: project,
            username: dataStore.authenticationManager.authStatePermanentUsername,
            userID: permanentUser?.userID,
            globalUserID: permanentUser?.globalUserID,
            savedSlideDataDelegate: dataStore.savedPageList,
            legacyPageViewsDataDelegate: dataStore,
            mainPageIdentifier: dataStore
        )
    }

    var theme: Theme
    var navigationController: UINavigationController

    let dataStore: MWKDataStore
    let dataController: WMFYearInReviewDataController

    weak var badgeDelegate: YearInReviewBadgeDelegate?

    /// The slide id reported for actions taken on the first slide. An announcement entry point
    /// overrides it so the funnel records where the flow was opened from.
    private var introSlideLoggingID: String = "profile"

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
        let viewModel = WMFYearInReviewViewModel(
            slides: slideFactory.makeSlides(
                userDataState: (try? dataController.fetchUserDataState()) ?? .lowData,
                forcesAllEmptyStates: dataController.forcesAllEmptyStates
            ),
            localizedStrings: slideFactory.makeLocalizedStrings(),
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
    
    private func shareSlideImage(slideID: String) {
        Task { @MainActor [weak self] in
            guard let self,
                  let slide = self.viewModel?.slides.first(where: { $0.id == slideID }),
                  let presenter = self.navigationController.presentedViewController else {
                return
            }

            do {
                // 3 seconds is a placeholder. Design decides when the artwork is at rest.
                let image = try await WMFRiveImageExporter.image(for: slide, poseTime: 3, caption: "Made with the Wikipedia App")
                let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = presenter.view
                presenter.present(activityViewController, animated: true)
            } catch {
                #if DEBUG
                print("[YiRShareExport] \(error.localizedDescription)")
                #endif
            }
        }
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
        case .share(let slideID):
            shareSlideImage(slideID: slideID)
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
