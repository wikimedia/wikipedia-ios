import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

final class TabsOverviewCoordinator: Coordinator {
    var navigationController: UINavigationController
    var theme: Theme
    let dataStore: MWKDataStore
    private let dataController: WMFArticleTabsDataController
    private let summaryController: ArticleSummaryController
    
    @discardableResult
    func start() -> Bool {
        if shouldShowEntryPoint() {
            presentTabs()
            return true
        } else {
            return false
        }
    }
    
    func shouldShowEntryPoint() -> Bool {
        return dataController.shouldShowArticleTabs
    }
    
    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        guard let dataController = WMFArticleTabsDataController.shared else {
            fatalError("Failed to create WMFArticleTabsDataController")
        }
        self.dataController = dataController
        self.summaryController = dataStore.articleSummaryController
    }
    
    private func presentTabs() {
        
        let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void = { [weak self] tab in
            self?.tappedTab(tab)
        }
        
        let didTapAddTab: () -> Void = { [weak self] in
            self?.tappedAddTab()
        }
        
        let populateSummary: @Sendable (WMFArticleTabsDataController.WMFArticleTab) async -> WMFArticleTabsDataController.WMFArticleTab = { [weak self] tab in
            guard let self = self else {
                return tab
            }
            return await self.populateArticleSummaryAsync(tab)
        }
        
        let localizedStrings = WMFArticleTabsViewModel.LocalizedStrings(
            navBarTitleFormat: WMFLocalizedString("tabs-navbar-title-format", value: "{{PLURAL:%1$d|%1$d tab|%1$d tabs}}", comment: "$1 is the amount of tabs. Navigation title for tabs, displaying how many open tabs."),
            mainPageSubtitle: WMFLocalizedString("tabs-main-page-subtitle", value: "Wikipedia’s daily highlights", comment: "Main page subtitle"),
            mainPageDescription: WMFLocalizedString("tabs-main-page-description", value: "Discover featured articles, the latest news, interesting facts, and key stats on Wikipedia’s main page.", comment: "Main page description"),
            closeTabAccessibility: WMFLocalizedString("tabs-close-tab", value: "Close tab", comment: "Accessibility label for close tab button"),
            openTabAccessibility: WMFLocalizedString("tabs-open-tab", value: "Open tab", comment: "Accessibility label for opening a tab")
        )
        
        let articleTabsViewModel = WMFArticleTabsViewModel(dataController: dataController, localizedStrings: localizedStrings, didTapTab: didTapTab, didTapAddTab: didTapAddTab, populateSummary: populateSummary)
        let articleTabsView = WMFArticleTabsView(viewModel: articleTabsViewModel)
        
        let hostingController = WMFArticleTabsHostingController(rootView: articleTabsView, viewModel: articleTabsViewModel,
                                                                doneButtonText: CommonStrings.doneTitle)
        let navVC = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)

        navigationController.present(navVC, animated: true, completion: nil)
    }
    
    private func populateArticleSummaryAsync(_ tab: WMFArticleTabsDataController.WMFArticleTab) async -> WMFArticleTabsDataController.WMFArticleTab {
        await withCheckedContinuation { continuation in
            self.populateArticleSummary(tab) { populatedTab in
                continuation.resume(returning: populatedTab)
            }
        }
    }
    
    private func populateArticleSummary(_ tab: WMFArticleTabsDataController.WMFArticleTab, completion: @escaping (WMFArticleTabsDataController.WMFArticleTab) -> Void) {
        
        guard let topArticle = tab.articles.last,
            let siteURL = topArticle.project.siteURL,
            let articleURL = siteURL.wmf_URL(withTitle: topArticle.title),
            let key = articleURL.wmf_inMemoryKey else {
            completion(tab)
            return
        }
        
        summaryController.updateOrCreateArticleSummaryForArticle(withKey: key, cachePolicy: .reloadRevalidatingCacheData) { article, error in
            if let error {
                DDLogError("Error fetching summaries: \(error)")
                completion(tab)
                return
            }
            
            guard let article else {
                completion(tab)
                return
            }
            
            var newArticles = Array(tab.articles.prefix(tab.articles.count - 1))
            let newArticle = WMFArticleTabsDataController.WMFArticle(identifier: topArticle.identifier, title: topArticle.title, description: article.wikidataDescription, summary: article.snippet, imageURL: article.thumbnailURL, project: topArticle.project)
            newArticles.append(newArticle)
            let newTab = WMFArticleTabsDataController.WMFArticleTab(identifier: tab.identifier, timestamp: tab.timestamp, isCurrent: tab.isCurrent, articles: newArticles)
            completion(newTab)
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

            let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: tabConfig)
            articleCoordinator.start()
        }

        navigationController.dismiss(animated: true)
    }
    
    private func tappedAddTab() {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .assignNewTabAndSetToCurrent)
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }
}

extension UIViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
}
