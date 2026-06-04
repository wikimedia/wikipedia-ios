import UIKit
import SwiftUI
import MessageUI
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import CocoaLumberjackSwift

/// Coordinator that presents the Which Came First game, starting with the splash screen.
@MainActor
final class WhichCameFirstCoordinator: NSObject, Coordinator {

    // MARK: - Properties

    var navigationController: UINavigationController
    private let theme: Theme
    private let gamesDataController = WMFGamesDataController()

    /// The modal navigation controller that hosts the splash screen and game screens.
    private weak var gameNavigationController: UINavigationController?
    private let dataStore: MWKDataStore
    private let project: WMFProject?

    var didFinish: (() -> Void)?
    // MARK: - Instrumentation

    private lazy var instrument = TestKitchenAdapter.shared.client
        .getInstrument(name: "apps-games")
        .setDefaultActionSource("wiki_game")
        .startFunnel(name: "wiki_game")

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, siteURL: URL?) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.project = Self.resolveProject(siteURL: siteURL)
    }

    private static func resolveProject(siteURL: URL?) -> WMFProject? {
        if let siteURL, let languageCode = siteURL.wmf_languageCode {
            let language = WMFLanguage(languageCode: languageCode, languageVariantCode: siteURL.wmf_languageVariantCode)
            return WMFProject.wikipedia(language)
        }
        if let language = WMFDataEnvironment.current.primaryAppLanguage {
            return WMFProject.wikipedia(language)
        }
        return nil
    }

    // MARK: - Coordinator

    @discardableResult
    func start() -> Bool {

        // do not show alert if user already tapped card
        gamesDataController.markGamesAnnouncementSeen()

        let splashViewController = makeSplashViewController()
        let nav = WMFComponentNavigationController(
            rootViewController: splashViewController,
            modalPresentationStyle: .fullScreen
        )
        gameNavigationController = nav
        navigationController.present(nav, animated: true)

        return true
    }
    // MARK: - Factory

    private func makeSplashViewController() -> WMFGamesSplashScreenViewController {
        let viewModel = WMFGamesSplashScreenViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .calendar),
            dateString: formattedTodayDateString(),
            didTapPlay: { [weak self] in
                self?.logClick(actionSource: "game_start", elementId: "game_play_start")
                self?.showGame()
            },
            didTapAbout: { [weak self] in
                self?.logClick(actionSource: "game_start", actionSubtype: "splash_overflow", elementId: "about")
                self?.showAbout()
            },
            didTapClose: { [weak self] in
                self?.logClick(actionSource: "game_start", elementId: "exit_button")
                self?.didFinish?()
            },
            didTapLearnMore: { [weak self] in
                self?.logClick(actionSource: "game_start", actionSubtype: "splash_overflow", elementId: "learn_more")
                self?.showAbout()
            },
            didTapReportProblem: { [weak self] in
                self?.logClick(actionSource: "game_start", actionSubtype: "splash_overflow", elementId: "problem_report")
                self?.showReportProblem()
            }
        )

        updatePlayButtonTitleIfNeeded(viewModel: viewModel)

        return WMFGamesSplashScreenViewController(viewModel: viewModel)
    }

    /// Fetches today's session and delegates play button title updates to the view model.
    private func updatePlayButtonTitleIfNeeded(viewModel: WMFGamesSplashScreenViewModel) {
        guard let project else { return }
        let todayDateString = formattedTodayISODateString()

        Task { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            guard let session = try? await self.gamesDataController.fetchWhichCameFirstDailySession(date: todayDateString, project: project) else {
                // Fetch failed — fire impression without context of is first visit
                self.logImpression(actionSource: "game_start", actionSubtype: "game_play_start")
                return
            }
            viewModel.update(sessionStatus: session.status)
            
            // Re-fire impression now that we know session status
            let isReturning = session.status == .completed
            let context: [String: String]? = isReturning ? ["is_first_visit": "false"] : nil
            self.logImpression(actionSource: "game_start", actionSubtype: "game_play_start", actionContext: context)
        }
    }

    // MARK: - Navigation

    private func showGame() {
        guard let project,
              let gameNav = gameNavigationController else { return }
        let isLoggedIn = dataStore.authenticationManager.authStateIsPermanent
        let viewModel = WMFWhichCameFirstViewModel(date: formattedTodayISODateString(), project: project)

        viewModel.didTapShare = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.logClick(actionSource: "game_end", elementId: "share_score_button")
            self.showShare(gameViewModel: viewModel)
        }
        viewModel.isLoggedIn = isLoggedIn
        viewModel.onLogIn = { [weak self] in
            self?.logClick(actionSource: "game_end", elementId: "login_button")
            self?.showLogin()
        }
        viewModel.onArticleTap = { [weak self] url in
            self?.logClick(actionSource: "game_end", actionSubtype: "article_overflow", elementId: "article_open")
            self?.openArticle(url: url, inNewTab: false)
        }
        viewModel.onArticleOpenInNewTab = { [weak self] url in
            self?.logClick(actionSource: "game_end", actionSubtype: "article_overflow", elementId: "article_open_tab")
            WMFArticleTabsDataController.shared.didTapOpenNewTab()
            ArticleTabsFunnel.shared.logLongPressOpenInNewTab()
            self?.openArticle(url: url, inNewTab: true)
        }
        viewModel.onArticleOpenInBackgroundTab = { [weak self] url in
            self?.logClick(actionSource: "game_end", actionSubtype: "article_overflow", elementId: "article_open_background")
            self?.openArticleInBackgroundTab(url: url)
        }
        viewModel.onArticleSaveForLater = { [weak self] url in
            self?.logClick(actionSource: "game_end", actionSubtype: "article_overflow", elementId: "article_save")
            self?.saveArticle(url: url)
        }
        viewModel.onArticleUnsave = { [weak self] url in
            self?.logClick(actionSource: "game_end", actionSubtype: "article_overflow", elementId: "article_unsave")
            self?.unsaveArticle(url: url)
        }
        viewModel.onCheckSavedState = { [weak self] url in
            self?.dataStore.savedPageList.isAnyVariantSaved(url) ?? false
        }
        viewModel.onArticleShare = { [weak self] url in
            self?.logClick(actionSource: "game_end", actionSubtype: "article_overflow", elementId: "article_share")
            self?.shareArticle(url: url)
        }
        viewModel.onArticleTapToEvent = { [weak self] url in
            self?.logClick(actionSource: "game_end", elementId: "article_open")
            self?.openArticle(url: url, inNewTab: false)
        }
        viewModel.didTapLearnMore = { [weak self, weak viewModel] in
            let source = viewModel?.isGameInProgress == true ? "game_play" : "game_end"
            self?.logClick(actionSource: source, actionSubtype: "game_overflow", elementId: "learn_more")
            self?.showAbout()
        }
        viewModel.didTapReportProblem = { [weak self, weak viewModel] in
            let source = viewModel?.isGameInProgress == true ? "game_play" : "game_end"
            self?.logClick(actionSource: source, actionSubtype: "game_overflow", elementId: "problem_report")
            self?.showReportProblem()
        }

        // Slide-level instrumentation
        viewModel.didImpressionSlide = { [weak self] slideIndex in
            self?.logImpression(actionSource: "game_play", actionSubtype: "game_play_\(slideIndex)")
        }
        viewModel.didTapExitDuringPlay = { [weak self] slideIndex in
            self?.logClick(actionSource: "game_play", actionSubtype: "game_play_\(slideIndex)", elementId: "exit_button")
        }
        viewModel.didSubmitAnswer = { [weak self] slideIndex in
            self?.logClick(actionSource: "game_play", actionSubtype: "game_play_\(slideIndex)", elementId: "answer_submit")
        }
        viewModel.didFinishGame = { [weak self] in
            self?.logImpression(actionSource: "game_end")
        }

        let gameVC = WMFWhichCameFirstHostingController(viewModel: viewModel)
        
        gameNav.setViewControllers([gameVC], animated: true)
    }

    private func showLogin() {
        guard let gameNav = gameNavigationController,
              let hostingVC = gameNav.viewControllers.first as? WMFWhichCameFirstHostingController else { return }
        let gameViewModel = hostingVC.viewModel
        
        let loginCoordinator = LoginCoordinator(navigationController: gameNav, theme: theme, loggingCategory: .game)
        loginCoordinator.loginSuccessCompletion = { [weak self, weak gameViewModel, weak gameNav] in
            guard let self else { return }
            gameNav?.presentedViewController?.dismiss(animated: true)
            gameViewModel?.isLoggedIn = self.dataStore.authenticationManager.authStateIsPermanent
        }
        loginCoordinator.start()
    }

    private func showShare(gameViewModel: WMFWhichCameFirstViewModel) {
        guard let gameNav = gameNavigationController,
              let events = gameViewModel.makeShareArticleEvents(),
              let results = gameViewModel.makeShareQuestionResults() else { return }

        Task { [weak self, weak gameNav] in
            guard let self, let gameNav else { return }

            let summaryController = WMFArticleSummaryDataController.shared
            let imageController = WMFImageDataController.shared

            var articles: [WMFWhichCameFirstShareViewModel.ArticleItem] = []

            for (event, project) in events {
                guard let articleTitle = event.articleTitle else { continue }
                let cleanTitle = articleTitle.underscoresToSpaces

                // Fetch summary for description
                let summary = try? await summaryController.fetchArticleSummary(project: project, title: articleTitle)
                let description = summary?.description ?? summary?.extract

                // Fetch thumbnail image — prefer the event's known URL, fall back to summary's
                let thumbnailURL = event.thumbnailURL ?? summary?.thumbnailURL
                var image: UIImage?
                if let url = thumbnailURL,
                   let data = try? await imageController.fetchImageData(url: url) {
                    image = UIImage(data: data)
                }

                articles.append(.init(title: cleanTitle, description: description, image: image))
            }

            let shareViewModel = WMFWhichCameFirstShareViewModel(
                score: gameViewModel.score,
                totalQuestions: gameViewModel.totalQuestions,
                questionResults: results,
                articles: articles
            )

            let shareView = WMFWhichCameFirstShareView(viewModel: shareViewModel, theme: Theme.wmfTheme(from: self.theme))
            let renderer = ImageRenderer(content: shareView)
            renderer.scale = UIScreen.main.scale
            guard let image = renderer.uiImage else { return }

            let shareText = WMFLocalizedString("which-came-first-share-activity-text", value: "I'm playing \"Which came first?\" a daily trivia game on the Wikipedia iOS app https://apps.apple.com/app/apple-store/id324715238?pt=208305&ct=wiki_game_202605&mt=8", comment: "Text shared when a user shares the Which Came First game via Messages, Notes, or other text-based share targets.")
            let textProvider = WCFShareActivityContentProvider(
                text: shareText
            )
            let imageProvider = ShareAFactActivityImageItemProvider(image: image)
            let activityVC = UIActivityViewController(activityItems: [textProvider, imageProvider], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.print, .assignToContact, .addToReadingList]

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = gameNav.visibleViewController?.view
                popover.sourceRect = gameNav.visibleViewController?.view.bounds ?? .zero
                popover.permittedArrowDirections = []
            }

            gameNav.present(activityVC, animated: true)
        }
    }

    private func openArticle(url: URL, inNewTab: Bool) {
        let tabConfig: ArticleTabConfig = inNewTab ? .appendArticleAndAssignNewTabAndSetToCurrent : .appendArticleAndAssignCurrentTab
        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: url,
            dataStore: dataStore,
            theme: theme,
            source: .game,
            tabConfig: tabConfig
        )
        gameNavigationController?.dismiss(animated: true) {
            articleCoordinator.start()
        }
    }

    private func openArticleInBackgroundTab(url: URL) {
        guard let title = url.wmf_title,
              let languageCode = url.wmf_languageCode else { return }
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: url.wmf_languageVariantCode))
        let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: project, articleURL: url)

        Task {
            do {
                let articleTabsDataController = WMFArticleTabsDataController.shared
                articleTabsDataController.didTapOpenNewTab()
                let tabsCount = try await articleTabsDataController.tabsCount()
                let tabsMax = articleTabsDataController.tabsMax
                if tabsCount >= tabsMax {
                    if let currentTabIdentifier = try await articleTabsDataController.currentTabIdentifier() {
                        _ = try await articleTabsDataController.appendArticle(article, toTabIdentifier: currentTabIdentifier)
                    } else {
                        _ = try await articleTabsDataController.createArticleTab(initialArticle: article)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        WMFToastManager.sharedInstance.showRichToast(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousToasts: true)
                    }
                } else {
                    _ = try await articleTabsDataController.createArticleTab(initialArticle: article, setAsCurrent: false)
                    ArticleTabsFunnel.shared.logLongPressOpenInBackgroundTab()
                }
            } catch {
                DDLogError("Failed to open article in background tab: \(error)")
            }
        }
    }

    private func saveArticle(url: URL) {
        dataStore.savedPageList.addSavedPage(with: url)
        showReadingListToast(for: url)
        ReadingListsFunnel.shared.logSave(category: .game, label: nil, articleURL: url)
    }

    private func unsaveArticle(url: URL) {
        dataStore.savedPageList.removeEntry(with: url)
        ReadingListsFunnel.shared.logUnsave(category: .game, label: nil, articleURL: url)
    }

    private func showReadingListToast(for url: URL) {
        guard let article = dataStore.fetchArticle(with: url),
              let appVC = navigationController.tabBarController as? WMFAppViewController,
              let presenter = gameNavigationController?.visibleViewController else { return }
        appVC.readingListHintPresenter.toggle(presenter: presenter, article: article, theme: theme)
    }

    private func shareArticle(url: URL) {
        guard let gameNav = gameNavigationController else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = gameNav.visibleViewController?.view
            popover.sourceRect = gameNav.visibleViewController?.view.bounds ?? .zero
            popover.permittedArrowDirections = []
        }
        gameNav.present(activityVC, animated: true)
    }

    private func showAbout() {
        guard let gameNav = gameNavigationController,
              let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/%22Which_came_first%3F%22_Game") else { return }
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNav = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .fullScreen)
        gameNav.present(webNav, animated: true)
    }

    private func showReportProblem() {
        guard MFMailComposeViewController.canSendMail(),
              let gameNav = gameNavigationController else { return }

        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self

        mailVC.setSubject(WMFLocalizedString("games-email-report-subject", value: "Issue Report - Wikipedia games", comment: "Email subject line for reporting a problem with the Wikipedia games feature."))
        mailVC.setToRecipients(["ios-support@wikimedia.org"])

        let body = [
            WMFLocalizedString("games-email-report-body-encountered", value: "I have encountered a problem with the Wikipedia games feature:", comment: "Opening line of the problem report email body for the Wikipedia games feature."),
            CommonStrings.issueReportEmailBodyDescribeProblem,
            CommonStrings.issueReportEmailBodyBehavior,
            CommonStrings.issueReportEmailBodyProposedSolution
        ].joined(separator: "\n\n")
        mailVC.setMessageBody(body, isHTML: false)
        gameNav.present(mailVC, animated: true)
    }

    // MARK: - Instrumentation Helpers

    // Update logImpression to accept optional context:
    private func logImpression(actionSource: String, actionSubtype: String? = nil, actionContext: [String: String]? = nil) {
        instrument.submitInteraction(
            action: "impression",
            actionSource: actionSource,
            actionSubtype: actionSubtype,
            actionContext: actionContext
        )
    }

    private func logClick(actionSource: String, actionSubtype: String? = nil, elementId: String) {
        instrument.submitInteraction(
            action: "click",
            actionSource: actionSource,
            actionSubtype: actionSubtype,
            elementId: elementId
        )
    }

    // MARK: - Helpers

    private func formattedTodayDateString() -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return formatter.string(from: Date())
    }

    /// Returns today's date as a "YYYY-MM-DD" string for matching game session records.
    private func formattedTodayISODateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}

// MARK: - Mail Compose Delegate

extension WhichCameFirstCoordinator: @MainActor MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Share Content Provider

// @unchecked Sendable: UIActivityItemProvider is a legacy UIKit class with no Sendable conformance,
// required by UIActivityViewController. This usage is safe because the provider is short-lived,
// immutable after init, and only accessed on the main thread via UIActivityViewController callbacks.
private final class WCFShareActivityContentProvider: UIActivityItemProvider, @unchecked Sendable {

    let text: String

    init(text: String) {
        self.text = text
        super.init(placeholderItem: text)
    }

    override var item: Any {
        return text
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if let activityType, activityType.rawValue.lowercased().contains("instagram") {
            return nil
        }
        return text
    }
}
