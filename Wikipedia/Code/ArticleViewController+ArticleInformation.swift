extension ArticleViewController {
    func showLanguages() {
        guard let languagesVC = WMFArticleLanguagesViewController(articleURL: articleURL) else {
            showGenericError()
            return
        }
        themesPresenter.dismissReadingThemesPopoverIfActive(from: self)
        languagesVC.delegate = self
        presentEmbedded(languagesVC, style: .sheet)
    }
    
    func showDisambiguation(with pageURLs: [URL]) {
        let listVC = DisambiguationPagesViewController(with: pageURLs, siteURL: articleURL, dataStore: dataStore, theme: theme)
        push(listVC)
    }
    
    func showEditHistory() {
        guard let title = articleURL.wmf_title else {
            showGenericError()
            return
        }
        let historyVC = PageHistoryViewController(pageTitle: title, pageURL: articleURL)
        historyVC.apply(theme: theme)
        push(historyVC)
    }
    
    func showTalkPage() {
        guard let talkPageURL = articleURL.articleTalkPage else {
            showGenericError()
            return
        }
        navigate(to: talkPageURL)
    }
    
    func showCoordinate() {
        
    }
    
    func showPageIssues() {
        
    }
    
    func showReferences() {
        
    }
}



extension ArticleViewController: WMFLanguagesViewControllerDelegate {
    func languagesController(_ controller: WMFLanguagesViewController!, didSelectLanguage language: MWKLanguageLink!) {
        dismiss(animated: true) {
            self.navigate(to: language.articleURL())
        }
    }
}
