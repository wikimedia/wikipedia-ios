extension ArticleViewController {
    func shareArticle() {
        themesPresenter.dismissReadingThemesPopoverIfActive(from: self)
        webView.wmf_getSelectedText({ selectedText in
            self.shareArticle(with: selectedText)
        })
    }
    
    func shareArticle(with selectedText: String?) {
        guard let text = selectedText, !text.isEmpty else {
            let activity = addToReadingListActivity(with: self, eventLogAction: {
                self.readingListsFunnel.logArticleSaveInCurrentArticle(self.articleURL)
            })
            let vc = sharingActivityViewController(with: nil, button: toolbarController.shareButton, shareFunnel: shareFunnel, customActivity: activity)
            vc?.excludedActivityTypes = [.addToReadingList]
            if vc != nil {
                if let vc = vc {
                    self.present(vc, animated: true)
                }
            }
            return
        }
          let shareAFactActivity = CustomShareActivity(title: "Share-a-fact", imageName: "share-a-fact", action: {
            self.shareFunnel?.logHighlight()
            self.shareAFact(with: text)
          })
        guard let vc = sharingActivityViewController(with: nil, button: toolbarController.shareButton, shareFunnel: shareFunnel, customActivity: shareAFactActivity) else {
            return
        }
        present(vc, animated: true)
    }
    
    func sharingActivityViewController(with textSnippet: String?, button: UIBarButtonItem, shareFunnel: WMFShareFunnel?, customActivity: UIActivity?) -> ShareActivityController? {
        shareFunnel?.logShareButtonTappedResulting(inSelection: textSnippet)
        let vc: ShareActivityController
        let textActivitySource = WMFArticleTextActivitySource(article: article, shareText: textSnippet)
        if let customActivity = customActivity {
            vc = ShareActivityController(customActivity: customActivity, article: article, textActivitySource:textActivitySource)
        } else {
            vc = ShareActivityController(article: article, textActivitySource: textActivitySource)
        }
        vc.popoverPresentationController?.barButtonItem = button
        return vc
    }
    
    func shareAFact(with text: String) {
        guard let shareViewController = ShareViewController(text: text, article: article, theme: theme) else {
            return
        }
        present(shareViewController, animated: true)
    }
    
    
    func addToReadingListActivity(with presenter: UIViewController, eventLogAction: @escaping () -> Void) -> UIActivity? {
        let addToReadingListActivity = AddToReadingListActivity {
            let vc = AddArticlesToReadingListViewController(with: self.dataStore, articles: [self.article], theme: self.theme)
            vc.eventLogAction = eventLogAction
            let nc = WMFThemeableNavigationController(rootViewController: vc, theme: self.theme)
            nc.setNavigationBarHidden(true, animated: false)
            presenter.present(nc, animated: true)
        }
        return addToReadingListActivity
    }

}
