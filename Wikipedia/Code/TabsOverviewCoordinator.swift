import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

@MainActor
final class TabsOverviewCoordinator: NSObject, Coordinator {
    var navigationController: UINavigationController
    var theme: Theme
    let dataStore: MWKDataStore
    private let dataController: WMFArticleTabsDataController
    private let summaryController: ArticleSummaryController

    @discardableResult
    func start() -> Bool {
        presentTabs()
        return true
    }

    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        let dataController = WMFArticleTabsDataController.shared
        self.dataController = dataController
        self.summaryController = dataStore.articleSummaryController
    }

    private func surveyViewController() -> UIViewController {
        let subtitle = WMFLocalizedString("tabs-survey-title", value: "Help improve tabs. Are you satisfied with this feature?", comment: "Title for article tabs survey")
        
        let surveyLocalizedStrings = WMFSurveyViewModel.LocalizedStrings(
            title: CommonStrings.satisfactionSurveyTitle,
            cancel: CommonStrings.cancelActionTitle,
            submit: CommonStrings.surveySubmitActionTitle,
            subtitle: subtitle,
            instructions: nil,
            otherPlaceholder: CommonStrings.surveyAdditionalThoughts
        )

        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyVerySatisfied, apiIdentifer: "1"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveySatisfied, apiIdentifer: "2"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyNeutral, apiIdentifer: "3"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyUnsatisfied, apiIdentifer: "4"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyVeryUnsatisfied, apiIdentifer: "5")
        ]

        let surveyView = WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single, shouldShowMultilineText: true), cancelAction: { [weak self] in
            ArticleTabsFunnel.shared.logFeedbackClose()
            self?.navigationController.presentedViewController?.dismiss(animated: true)
        }, submitAction: { [weak self] options, otherText in
            ArticleTabsFunnel.shared.logFeedbackSubmit(selectedItems: options, comment: otherText)
            self?.navigationController.presentedViewController?.dismiss(animated: true, completion: {
                let image = UIImage(systemName: "checkmark.circle.fill")
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.feedbackSurveyToastTitle, subtitle: nil, image: image, type: .custom, customTypeName: "feedback-submitted", dismissPreviousAlerts: true)
            })
        })

        let hostedView = WMFComponentHostingController(rootView: surveyView)
        return hostedView
    }
    
    
    public func showAlertForArticleSuggestionsDisplayChangeConfirmation() {
        if dataController.userHasHiddenArticleSuggestionsTabs {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(
                WMFLocalizedString("tabs-suggested-articles-hide-suggestions-confirmation", value: "Suggestions are now hidden", comment: "Confirmation on hiding of the suggested articles in tabs."),
                subtitle: nil,
                buttonTitle: nil,
                image: WMFSFSymbolIcon.for(symbol: .checkmark),
                dismissPreviousAlerts: true
            )
        }
    }
    
    func closeAllTabsTitle(numberTabs: Int) -> String {
        let format = WMFLocalizedString("close-all-tabs-confirmation-title-with-value", value: "Close {{PLURAL:%1$d|%1$d tab|%1$d tabs}}?", comment: "Title of alert that asks user if they want to delete all tabs, $1 is representative of the number of tabs they have open.")
        return String.localizedStringWithFormat(format, numberTabs)
    }

    func closeAllTabsSubtitle(numberTabs: Int) -> String {
        let format = WMFLocalizedString("close-all-tabs-confirmation-subtitle-with-value", value: "Do you want to close {{PLURAL:%1$d|%1$d tab|%1$d tabs}}? This action can’t be undone.", comment: "Subtitle of alert that asks user to confirm all tabs deletion. $1 represents the number of tabs.")
        return String.localizedStringWithFormat(format, numberTabs)
    }

    func closedAlertsNotification(numberTabs: Int) -> String {
        let format = WMFLocalizedString("closed-all-tabs-confirmation-with-value", value: "{{PLURAL:%1$d|%1$d tab|%1$d tabs}} closed.", comment: "Confirmation title of deleting all tabs. $1 is the number of tabs deleted.")
        return String.localizedStringWithFormat(format, numberTabs)
    }
    
    private func presentTabs() {
        
        let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void = { [weak self] tab in
            self?.tappedTab(tab)
        }
        
        let didTapAddTab: () -> Void = { [weak self] in
            guard let self else { return }
            self.tappedAddTab()
        }
        
        let didTapDone: () -> Void = { [weak self] in
            guard let self else { return }
            self.tappedDone()
            self.logArticleTabsOverviewTappedDone()
        }

        let didTapShareTab: (WMFArticleTabsDataController.WMFArticleTab, CGRect?) -> Void = { [weak self] tab, frame in
            guard let self else { return }
            self.tappedShareTab(tab, sourceFrameInWindow: frame)
        }
        
        let showSurveyClosure = { [weak self] in
            if let shouldShowSurvey = self?.dataController.shouldShowSurvey(), shouldShowSurvey {
                guard let presentedVC = self?.navigationController.presentedViewController else { return }
                let surveyVC = self?.surveyViewController()
                guard let surveyVC else { return }
                ArticleTabsFunnel.shared.logFeedbackImpression()
                presentedVC.present(surveyVC, animated: true)
                
                surveyVC.modalPresentationStyle = .pageSheet
                if let sheet = surveyVC.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersGrabberVisible = false
                }
            }
        }
        
        Task { [weak self] in
            guard let self else { return }
            let articleTabsCount = (try? await dataController.tabsCount()) ?? 0
            
            let localizedStrings = WMFArticleTabsViewModel.LocalizedStrings(
                navBarTitleFormat: WMFLocalizedString("tabs-navbar-title-format", value: "{{PLURAL:%1$d|%1$d tab|%1$d tabs}}", comment: "$1 is the amount of tabs. Navigation title for tabs, displaying how many open tabs."),
                mainPageTitle: nil,
                mainPageSubtitle: CommonStrings.mainPageSubtitle,
                mainPageDescription: CommonStrings.mainPageDescription,
                closeTabAccessibility: WMFLocalizedString("tabs-close-tab", value: "Close tab", comment: "Accessibility label for close tab button"),
                openTabAccessibility: WMFLocalizedString("tabs-open-tab", value: "Open tab", comment: "Accessibility label for opening a tab"),
                shareTabButtonTitle: CommonStrings.shareActionTitle,
                closeAllTabs: CommonStrings.closeAllTabs,
                cancelActionTitle: CommonStrings.cancelActionTitle,
                closeAllTabsTitle: { count in
                    self.closeAllTabsTitle(numberTabs: count)
                },
                closeAllTabsSubtitle: { count in
                    self.closeAllTabsSubtitle(numberTabs: count)
                },
                closedAlertsNotification: closedAlertsNotification(numberTabs: articleTabsCount),
                hideSuggestedArticlesTitle: WMFLocalizedString("tabs-hide-suggested-articles", value: "Hide article suggestions", comment: "Hide suggested articles button title"),
                showSuggestedArticlesTitle: WMFLocalizedString("tabs-show-suggested-articles", value: "Show article suggestions", comment: "Show suggested articles button title"),
                emptyStateTitle: WMFLocalizedString("tabs-empty-view-title", value: "Your tabs will show up here", comment: "Title for the tabs overview screen when there are no tabs"),
                emptyStateSubtitle: WMFLocalizedString("tabs-empty-view-subtitle", value: "Tap “+” to add tabs to this space or long press an article link to open it in a new tab.", comment: "Subtitle for the tabs overview screen when there are no tabs")
            )

            let articleTabsViewModel = WMFArticleTabsViewModel(
                dataController: dataController,
                localizedStrings: localizedStrings,
                loggingDelegate: self,
                didTapTab: didTapTab,
                didTapAddTab: didTapAddTab,
                didTapShareTab: didTapShareTab,
                didTapDone: didTapDone,
                didToggleSuggestedArticles: showAlertForArticleSuggestionsDisplayChangeConfirmation
            )

            let articleTabsView = WMFArticleTabsView(viewModel: articleTabsViewModel)
            let hostingController = WMFArticleTabsHostingController(
                rootView: articleTabsView,
                viewModel: articleTabsViewModel,
                doneButtonText: CommonStrings.doneTitle,
                articleTabsCount: articleTabsCount
            )
            
            let navVC = WMFComponentNavigationController(
                rootViewController: hostingController,
                modalPresentationStyle: .overFullScreen,
                customBarBackgroundColor: theme.colors.midBackground
            )
            
            navigationController.present(navVC, animated: true) { [weak self] in
                self?.dataController.updateSurveyDataTabsOverviewSeenCount()
                guard self != nil else { return }
                showSurveyClosure()
            }
        }
    }
    
    private func tappedArticle(_ item: HistoryItem) {
        if let articleURL = item.url {
            let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .undefined, tabConfig: .appendArticleAndAssignNewTabAndSetToCurrent)
            if let presented = navigationController.presentedViewController {
                presented.dismiss(animated: true) {
                    articleCoordinator.start()
                }
            }
        }
    }

    // Returns unordered set of URLs
    @MainActor
    private func getRecentTabArticleURLs() async throws -> Set<URL> {
        let articleTabs = try await dataController.fetchAllArticleTabs()
        let articleLimit = 1
        let tabLimit = 2

        guard !articleTabs.isEmpty else {
            return []
        }

        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let mainPageURL = siteURL.wmf_URL(withTitle: "Main Page") else {
            return []
        }

        var urls = Set<URL>()
        urls.reserveCapacity(tabLimit * articleLimit)

        let nonMainPageTabs = articleTabs.filter { tab in
            tab.articles.contains { $0.articleURL != mainPageURL }
        }

        let newestTabs = nonMainPageTabs.reversed().prefix(tabLimit)

        for tab in newestTabs {
            for article in tab.articles.reversed() {
                guard let url = article.articleURL else { break }
                if url != mainPageURL {
                    urls.insert(url)
                }
                
                if urls.count >= articleLimit {
                    break
                }
            }
        }

        return urls
    }

    private func stringWithLocalizedCurrentSiteLanguageReplacingPlaceholder(in format: String, fallingBackOn genericString: String
    ) -> String {
        guard let code = self.dataStore.languageLinkController.appLanguage?.languageCode else {
            return genericString
        }

        if let language = Locale.current.localizedString(forLanguageCode: code) {
            return String.localizedStringWithFormat(format, language)
        } else {
            if code == "test" {
                return String.localizedStringWithFormat(format, "Test")
            } else if code == "test2" {
                return String.localizedStringWithFormat(format, "Test 2")
            } else {
                return genericString
            }
        }
    }

    private func tappedTab(_ tab: WMFArticleTabsDataController.WMFArticleTab) {
        // If navigation controller is already displaying tab, just dismiss without pushing on any more tabs.
        if let displayedArticleViewController = navigationController.viewControllers.last as? ArticleViewController,
           let displayedTabIdentifier = displayedArticleViewController.coordinator?.tabIdentifier {
            if displayedTabIdentifier == tab.identifier {
                navigationController.dismiss(animated: true)
                return
            }
        }
        
        // Only push on last article
        if let article = tab.articles.last {
            guard let siteURL = article.project.siteURL,
                  let articleURL = siteURL.wmf_URL(withTitle: article.title) else {
                return
            }
            
            let tabConfig = ArticleTabConfig.assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers(tabIdentifier: tab.identifier, tabItemIdentifier: article.identifier))
                // isRestoringState = true allows for us to retain the previous scroll position
            let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, isRestoringState: true, tabConfig: tabConfig)
                articleCoordinator.start()

        }
        navigationController.dismiss(animated: true)
    }
    
    private func tappedAddTab() {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: MWKDataStore.shared(),
            theme: theme,
            needsAnimation: false,
            source: .undefined,
            tabConfig: .assignNewTabAndSetToCurrent,
            needsFocusOnSearch: true)
        ArticleTabsFunnel.shared.logAddNewBlankTab()
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }
    
    private func tappedDone() {
        navigationController.dismiss(animated: true)
    }

    private func tappedShareTab(_ tab: WMFArticleTabsDataController.WMFArticleTab, sourceFrameInWindow: CGRect?) {
        guard let article = tab.articles.last, let url = article.articleURL else { return }
        let articleURL = url.wmf_URLForTextSharing
        let presenter = navigationController.presentedViewController ?? navigationController
        shareURL(articleURL, from: presenter, sourceFrameInWindow: sourceFrameInWindow)
    }


    private func shareURL(_ url: URL, from presenter: UIViewController, sourceFrameInWindow: CGRect?) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = presenter.view
            if let rectInWindow = sourceFrameInWindow {
                let rectInPresenter = presenter.view.convert(rectInWindow, from: presenter.view.window)
                pop.sourceRect = rectInPresenter
            } else {
                pop.sourceRect = presenter.view.bounds
            }
        }

        presenter.present(activityVC, animated: true)
    }

}

extension TabsOverviewCoordinator: WMFArticleTabsLoggingDelegate {

    func logArticleTabsOverviewTappedDone() {
        ArticleTabsFunnel.shared.logTabsOverviewClose()
    }

    func logArticleTabsOverviewImpression() {
        ArticleTabsFunnel.shared.logTabsOverviewImpression()
    }
    
    func logArticleTabsOverviewTappedCloseTab() {
        ArticleTabsFunnel.shared.logTabsOverviewCloseTab()
    }
    
    nonisolated func logArticleTabsArticleClick(wmfProject: WMFProject?) {
        if let url = wmfProject?.siteURL, let project =  WikimediaProject(siteURL:url) {
            ArticleTabsFunnel.shared.logTabsOverviewArticleClick(project: project)
        }
    }
    
    func logArticleTabsOverviewTappedHideSuggestions() {
        ArticleTabsFunnel.shared.logTabsOverflowHideArticleSuggestionsTap()
    }
    
    func logArticleTabsOverviewTappedShowSuggestions() {
        ArticleTabsFunnel.shared.logTabsOverflowShowArticleSuggestionsTap()
    }
    
    func logArticleTabsOverviewTappedCloseAllTabs() {
        ArticleTabsFunnel.shared.logTabsOverflowCloseAllTabsTap()
    }
    
    func logArticleTabsOverviewTappedCloseAllTabsConfirmCancel() {
        ArticleTabsFunnel.shared.logTabsOverviewCloseAllTabsConfirmCancelTap()
    }
    
    func logArticleTabsOverviewTappedCloseAllTabsConfirmClose() {
        ArticleTabsFunnel.shared.logTabsOverviewCloseAllTabsConfirmCloseTap()
    }
}

/// Manages the lifecycle of TabsOverviewCoordinator independently of article tabs.
/// Ensures the tabs UI works even if the current article tab is closed.
@MainActor
final class TabsCoordinatorManager {

    static let shared = TabsCoordinatorManager()

    private var tabsOverviewCoordinator: TabsOverviewCoordinator?

    func presentTabsOverview(from navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        let coordinator = TabsOverviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        self.tabsOverviewCoordinator = coordinator
        coordinator.start()
    }
}
