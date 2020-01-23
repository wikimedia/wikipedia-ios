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
        article.isSaved = !article.isSaved
        try? article.managedObjectContext?.save()
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
        guard let languagesVC = WMFArticleLanguagesViewController(articleURL: articleURL) else {
            return
        }
        themesPresenter.dismissReadingThemesPopoverIfActive(from: self)
        languagesVC.delegate = self
        presentEmbedded(languagesVC, style: .sheet)
    }
}

extension ArticleViewController: WMFLanguagesViewControllerDelegate {
    func languagesController(_ controller: WMFLanguagesViewController!, didSelectLanguage language: MWKLanguageLink!) {
        dismiss(animated: true) {
            self.navigate(to: language.articleURL())
        }
    }
}
