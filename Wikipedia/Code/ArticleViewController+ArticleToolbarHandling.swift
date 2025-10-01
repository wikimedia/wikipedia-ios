import WMFComponents
import WMFData

extension ArticleViewController: ArticleToolbarHandling {
    func backInTab(article: WMFData.WMFArticleTabsDataController.WMFArticle, controller: ArticleToolbarController) {
        guard let navigationController,
              let siteURL = article.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: article.title),
              let tabIdentifier = coordinator?.tabIdentifier,
              let tabItemIdentifier = article.identifier else {
            return
        }
        
        let identifiers = WMFArticleTabsDataController.Identifiers(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, needsAnimation: false, source: .undefined, tabConfig: .adjacentArticleInTab(identifiers))
        articleCoordinator.start()
    }
    
    func forwardInTab(article: WMFData.WMFArticleTabsDataController.WMFArticle, controller: ArticleToolbarController) {
        guard let navigationController,
              let siteURL = article.project.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: article.title),
              let tabIdentifier = coordinator?.tabIdentifier,
              let tabItemIdentifier = article.identifier else {
            return
        }
        
        let identifiers = WMFArticleTabsDataController.Identifiers(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, needsAnimation: false, source: .undefined, tabConfig: .adjacentArticleInTab(identifiers))
        articleCoordinator.start()
    }
    
    
    func showTableOfContents(from controller: ArticleToolbarController) {
        showTableOfContents()
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarTOC)
    }
    
    func hideTableOfContents(from controller: ArticleToolbarController) {
        hideTableOfContents()
    }
    
    var isTableOfContentsVisible: Bool {
        return tableOfContentsController.viewController.displayMode == .inline && tableOfContentsController.viewController.isVisible
    }
    
    func toggleSave(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSave)
        let isSaved = dataStore.savedPageList.toggleSavedPage(for: articleURL)
        if isSaved {
            readingListsFunnel.logArticleSaveInCurrentArticle(articleURL)
            NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSaveSuccess)
        } else {
            readingListsFunnel.logArticleUnsaveInCurrentArticle(articleURL)
        }
    }
    
    func showThemePopover(from controller: ArticleToolbarController) {
        themesPresenter.showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarAppearence)
    }
    
    func saveButtonWasLongPressed(from controller: ArticleToolbarController) {
        let addArticlesToReadingListVC = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        let navigationController = WMFComponentNavigationController(rootViewController: addArticlesToReadingListVC, modalPresentationStyle: .overFullScreen)
        present(navigationController, animated: true)
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSave)
    }
    
    func showLanguagePicker(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarLang)
        showLanguages()
    }
    
    func share(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarShare)
        shareArticle()
    }
    
    func showFindInPage(from controller: ArticleToolbarController) {
        NavigationEventsFunnel.shared.logEvent(action: .articleToolbarSearch)
        showFindInPage()
    }
    
    func showRevisionHistory(from controller: ArticleToolbarController) {
        showEditHistory()
    }
    
    func watch(from controller: ArticleToolbarController) {
        watch()
    }
    
    func unwatch(from controller: ArticleToolbarController) {
        unwatch()
    }
    
    func showArticleTalkPage(from controller: ArticleToolbarController) {
        showTalkPage()
    }
    
    func editArticle(from controller: ArticleToolbarController) {
        showEditorForFullSource()
    }
    
}
