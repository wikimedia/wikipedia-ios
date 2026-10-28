import CocoaLumberjackSwift
import SwiftUI
import UIKit
import WMF
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
    @MainActor
    private static var reportTask: Task<Void, Never>?

    /// Builds the report, or waits for the build that is already running. The build is not tied to a
    /// screen, so it finishes when the reader closes the announcement. Like Android, the report is
    /// built when the reader asks for Year in Review, not at launch, and after any log in.
    @MainActor
    static func buildReport(dataStore: MWKDataStore) async {
        if let reportTask {
            await reportTask.value
            return
        }
        let task = Task { @MainActor in
            do {
                try await populateReport(dataStore: dataStore)
            } catch {
                DDLogError("Error populating the Year in Review report: \(error)")
            }
            reportTask = nil
        }
        reportTask = task
        await task.value
    }

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
    /// TODO: add when data ticket is available
    private var introSlideLoggingID: String = ""

    /// The data state the announcement was built with. It picks the log in prompt copy. It does not
    /// pick the slides: those are chosen after the reader taps Explore and logs in.
    private var announcementDataState: WMFYearInReviewDataController.YiRDataState = .lowData

    /// The navigation controller the announcement is presented in. The slides replace the
    /// announcement inside it, so it holds whichever of the two is showing.
    private weak var announcementNavigationController: UINavigationController?

    private weak var viewModel: WMFYearInReviewViewModel?
    private weak var hostingController: WMFYearInReviewHostingController?
    private weak var announcementViewModel: WMFYearInReviewAnnouncementViewModel?

    /// The slides that `viewModel` shows. A donation turns "You matter" into "Thank you" only in the
    /// personalized slides.
    private var slidesExperience: WMFYearInReviewDataController.YiRSlidesExperience = .collective

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
        NotificationCenter.default.addObserver(self, selector: #selector(localDonationHistoryDidChange), name: WMFNSNotification.localDonationHistoryDidChange, object: nil)
    }
    
    @discardableResult
    func start() -> Bool {
        afterReportIsBuilt { [weak self] in
            self?.presentYearInReview()
        }
        return true
    }

    /// Builds the report, then runs `action`. The Explore button shows a spinner while it waits.
    private func afterReportIsBuilt(_ action: @escaping @MainActor () -> Void) {
        announcementViewModel?.isLoadingExplore = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            await Self.buildReport(dataStore: dataStore)
            announcementViewModel?.isLoadingExplore = false
            action()
        }
    }

    /// Loads the announcement data and shows the announcement. Returns true only when it is on screen.
    /// The caller decides whether a pop-up is allowed now, and what comes next when this returns false.
    @MainActor
    func presentFeatureAnnouncement(introSlideLoggingID: String) async -> Bool {
        guard dataController.shouldShowYearInReviewFeatureAnnouncement() else {
            return false
        }

        self.introSlideLoggingID = introSlideLoggingID

        return await presentAnnouncement()
    }

    /// Opens the announcement from an entry point the reader tapped, such as the Activity tab card.
    /// It skips the "should the pop-up show" check, because the reader asked for it.
    @discardableResult
    @MainActor
    func presentFeatureAnnouncementFromEntryPoint() async -> Bool {
        return await presentAnnouncement()
    }

    @MainActor
    private func presentAnnouncement() async -> Bool {
        let dataState = (try? await dataController.fetchDataState(mainPageIdentifier: dataStore)) ?? .lowData
        let readingDayCount = (try? await dataController.fetchReadingDayCount()) ?? 0

        // Something may have been presented while the data loaded.
        guard navigationController.presentedViewController == nil else {
            return false
        }

        announcementDataState = dataState
        let viewModel = announcementFactory.makeViewModel(
            dataState: dataState,
            readingDayCount: readingDayCount,
            delegate: self
        )

        announcementViewModel = viewModel
        let hostingController = WMFYearInReviewAnnouncementHostingController(viewModel: viewModel)
        // Full screen from the first frame, same style as the slides.
        let announcementNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)
        announcementNavigationController.isModalInPresentation = true
        // Year in Review is always light, whatever the system style is. The slides replace the
        // announcement inside this same navigation controller, so they keep it.
        announcementNavigationController.overrideUserInterfaceStyle = .light
        self.announcementNavigationController = announcementNavigationController
        navigationController.present(announcementNavigationController, animated: true)

        // Marked here, when it is on screen, so an early exit above does not use it up.
        dataController.hasPresentedYiRFeatureAnnouncement = true
        return true
    }

    // MARK: - Presentation

    /// Builds the slides and their hosting controller. Shared by the direct presentation and the
    /// in place transition from the announcement.
    ///
    /// The slides are chosen here, so after any log in. A logged-out reader always gets the
    /// collective slides.
    private func makeYearInReviewHostingController() -> WMFYearInReviewHostingController {
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        // `fetchSlidesExperience(isLoggedIn:)` runs on the main actor. This method only runs on the
        // main thread, because it presents view controllers.
        let experience = MainActor.assumeIsolated {
            (try? dataController.fetchSlidesExperience(isLoggedIn: isLoggedIn)) ?? .collective
        }

        let viewModel = WMFYearInReviewViewModel(
            slides: slideFactory.makeSlides(
                experience: experience,
                isLoggedIn: isLoggedIn,
                forcesAllEmptyStates: dataController.forcesAllEmptyStates
            ),
            localizedStrings: slideFactory.makeLocalizedStrings(),
            coordinatorDelegate: self,
            loggingDelegate: self
        )

        self.viewModel = viewModel
        self.slidesExperience = experience

        let hostingController = WMFYearInReviewHostingController(viewModel: viewModel)
        self.hostingController = hostingController
        return hostingController
    }

    private func presentYearInReview() {
        let hostingController = makeYearInReviewHostingController()
        let presentedNavigationController = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)
        // Year in Review is always light, whatever the system style is.
        presentedNavigationController.overrideUserInterfaceStyle = .light
        navigationController.present(presentedNavigationController, animated: true)

        // The reader has seen Year in Review, so the announcement no longer needs to show.
        dataController.hasSeenYiRIntroSlide = true
    }

    /// Replaces the announcement with the first slide inside the same full screen navigation
    /// controller, so nothing is dismissed and presented again.
    private func transitionAnnouncementToYearInReview() {
        guard let announcementNavigationController,
              announcementNavigationController.presentingViewController != nil else {
            presentYearInReview()
            return
        }

        let hostingController = makeYearInReviewHostingController()

        // The announcement blocks swipe to dismiss. The slides never did.
        announcementNavigationController.isModalInPresentation = false

        UIView.transition(with: announcementNavigationController.view, duration: 0.3, options: .transitionCrossDissolve) {
            announcementNavigationController.setViewControllers([hostingController], animated: false)
        }

        // The reader has seen Year in Review, so the announcement no longer needs to show.
        dataController.hasSeenYiRIntroSlide = true
    }

    // MARK: - Announcement log in prompt

    /// Asks logged-out readers to log in first. The slides open after the log in screen closes, and
    /// they are chosen then: logging in can open the personalized slides. Continuing without logging
    /// in, or closing the log in screen, opens the collective slides.
    private func presentAnnouncementLoginPrompt() {
        guard let announcement = navigationController.presentedViewController else {
            presentYearInReview()
            return
        }

        let copy = announcementFactory.makeLoginPromptCopy(dataState: announcementDataState)

        let alert = UIAlertController(title: copy.title, message: copy.message, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .light

        let loginAction = UIAlertAction(title: CommonStrings.joinLoginTitle, style: .default) { [weak self] _ in
            self?.dismissAnnouncement {
                self?.startAnnouncementLogin()
            }
        }

        let continueAction = UIAlertAction(title: CommonStrings.continueWithoutLoggingIn, style: .default) { [weak self] _ in
            self?.afterReportIsBuilt { [weak self] in
                self?.transitionAnnouncementToYearInReview()
            }
        }

        alert.addAction(loginAction)
        alert.addAction(continueAction)
        alert.preferredAction = loginAction
        alert.view.tintColor = theme.colors.link

        announcement.present(alert, animated: true)
    }

    private func startAnnouncementLogin() {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController, theme: theme, loggingCategory: .yir)

        // The log in screen calls this before it dismisses itself, so wait for that to finish.
        loginCoordinator.loginSuccessCompletion = { [weak self] in
            Task { @MainActor [weak self] in
                self?.presentYearInReviewAfterCurrentDismissal()
            }
        }

        loginCoordinator.loginDismissedCompletion = { [weak self] in
            Task { @MainActor [weak self] in
                self?.presentYearInReviewAfterCurrentDismissal()
            }
        }

        // Account creation leaves its screen up, so dismiss it here first.
        loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
            guard let self else { return }
            guard let accountCreation = navigationController.presentedViewController else {
                presentYearInReview()
                return
            }
            accountCreation.dismiss(animated: true) { [weak self] in
                self?.presentYearInReviewAfterCurrentDismissal()
            }
        }

        loginCoordinator.start()
    }

    /// Builds the report after the log in, then presents the slides once any dismissal in progress is done.
    private func presentYearInReviewAfterCurrentDismissal() {
        afterReportIsBuilt { [weak self] in
            guard let self else { return }
            guard let transitionCoordinator = navigationController.transitionCoordinator else {
                presentYearInReview()
                return
            }

            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                self?.presentYearInReview()
            }
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

    /// Apple Pay reports success on a timer, before the payment request returns. The donation is
    /// saved only when the request succeeds, so wait for the save, not for the success action.
    @objc private func localDonationHistoryDidChange() {
        Task { @MainActor [weak self] in
            self?.showThankYouSlideAfterDonation()
        }
    }

    /// The rebuilt slide reads the saved donation. The reader stays on the same slide, which
    /// becomes the "Thank you" version. Does nothing when Year in Review is closed, in the
    /// collective slides, or for a logged-out reader, who always sees "You matter".
    private func showThankYouSlideAfterDonation() {
        guard let viewModel,
              let slide = slideFactory.makeContributorSlide(experience: slidesExperience, isLoggedIn: dataStore.authenticationManager.authStateIsPermanent),
              slide.id == YearInReviewSlideViewModelFactory.contributorSlideID else {
            return
        }
        viewModel.replaceSlide(id: YearInReviewSlideViewModelFactory.nonContributorSlideID, with: slide)
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
        let webViewController = SinglePageWebViewController(configType: .standard(config), theme: .light)
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

    private var isExportingShareImage = false

    /// Shares a still image of the slide, with the share text and the app link.
    private func shareSlide(slideID: String) {
        guard !isExportingShareImage,
              let slide = viewModel?.slides.first(where: { $0.id == slideID }) else {
            return
        }
        isExportingShareImage = true
        let layoutDirection: LayoutDirection = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight

        Task { @MainActor [weak self] in
            defer { self?.isExportingShareImage = false }
            do {
                let image = try await WMFYearInReviewSlideImageExporter.image(
                    for: slide,
                    caption: CommonStrings.yearInReviewHighlightsCreatedWith,
                    layoutDirection: layoutDirection
                )
                self?.presentShareSheet(image: image)
            } catch {
                DDLogError("Could not make the Year in Review share image for \(slideID): \(error)")
                WMFToastManager.sharedInstance.showToast(CommonStrings.genericErrorDescription, sticky: false, dismissPreviousToasts: true)
            }
        }
    }

    /// The export takes about a second. If the reader closed the slides or opened another screen
    /// from them in that time, the share sheet does not open.
    private func presentShareSheet(image: UIImage) {
        guard let hostingController,
              let presenter = hostingController.navigationController,
              presenter.viewIfLoaded?.window != nil,
              presenter.presentedViewController == nil else {
            return
        }
        let text = YearInReviewShareTextItem(text: CommonStrings.yearInReviewShareText(url: WMFYearInReviewDataController.appShareLink))
        let activityViewController = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = presenter.view
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY, width: 0, height: 0)
        presenter.present(activityViewController, animated: true)
    }
}

/// The share text, left out where only the image can go. Instagram and TikTok share one item, and
/// the image is the priority.
private final class YearInReviewShareTextItem: NSObject, UIActivityItemSource {

    private static let imageOnlyActivityPrefixes = ["com.burbn.instagram", "com.zhiliaoapp.musically", "com.ss.iphone.ugc.Ame"]

    private let text: String

    init(text: String) {
        self.text = text
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let activityType,
              Self.imageOnlyActivityPrefixes.contains(where: { activityType.rawValue.hasPrefix($0) }) else {
            return text
        }
        return nil
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
        case .share(let slideID):
            shareSlide(slideID: slideID)
        case .donate(let getSourceRect, let slideLoggingID):
            donate(getSourceRect: getSourceRect, slideLoggingID: slideLoggingID)
        }
    }
}

// MARK: - WMFYearInReviewAnnouncementDelegate

extension YearInReviewCoordinator: WMFYearInReviewAnnouncementDelegate {

    func yearInReviewAnnouncementDidTapExplore() {
        guard dataStore.authenticationManager.authStateIsPermanent else {
            presentAnnouncementLoginPrompt()
            return
        }

        afterReportIsBuilt { [weak self] in
            self?.transitionAnnouncementToYearInReview()
        }
    }

    func yearInReviewAnnouncementDidTapClose() {
        navigationController.presentedViewController?.dismiss(animated: true) {
            WMFToastManager.sharedInstance.showToast(CommonStrings.youCanAccessYIRInActivity, sticky: false, dismissPreviousToasts: true)
        }
        // So the slides open at once the next time.
        let dataStore = dataStore
        Task { @MainActor in
            await Self.buildReport(dataStore: dataStore)
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
