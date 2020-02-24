extension ArticleViewController: ArticleToolbarHandling {
    func showTableOfContents(from controller: ArticleToolbarController) {
        showTableOfContents()
    }
    
    func hideTableOfContents(from controller: ArticleToolbarController) {
        hideTableOfContents()
    }
    
    var isTableOfContentsVisible: Bool {
        return tableOfContentsController.viewController.displayMode == .inline && tableOfContentsController.viewController.isVisible
    }
    
    func toggleSave(from viewController: ArticleToolbarController) {
        dataStore.savedPageList.toggleSavedPage(for: articleURL)
    }
    
    func showThemePopover(from controller: ArticleToolbarController) {
        themesPresenter.showReadingThemesControlsPopup(on: self, responder: self, theme: theme)
    }
    
    func saveButtonWasLongPressed(from controller: ArticleToolbarController) {
        let addArticlesToReadingListVC = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        let nc = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListVC, theme: theme)
        nc.setNavigationBarHidden(false, animated: false)
        present(nc, animated: true)
    }
    
    func showLanguagePicker(from controller: ArticleToolbarController) {
        showLanguages()
    }
    
    func share(from controller: ArticleToolbarController) {
        shareArticle()
    }
    
    func showFindInPage(from controller: ArticleToolbarController) {
        showFindInPage()
    }
}
