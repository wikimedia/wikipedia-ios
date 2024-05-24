extension ArticleViewController: ArticleToolbarHandling {
    
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
        let nc = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListVC, theme: theme)
        nc.setNavigationBarHidden(false, animated: false)
        present(nc, animated: true)
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
