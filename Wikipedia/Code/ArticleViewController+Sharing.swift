extension ArticleViewController {
    func shareArticle() {
        themesPresenter.dismissReadingThemesPopoverIfActive(from: self)
        webView.wmf_getSelectedText({ [weak self] selectedText in
            guard let self = self else {
                return
            }
            self.shareArticle(with: selectedText)
            NavigationEventsFunnel.shared.logEvent(action: .articleToolbarShareSuccess)
        })
    }
    
    func shareArticle(with selectedText: String?) {
        var activities: [UIActivity] = []
        let readingListActivity = addToReadingListActivity(with: self, eventLogAction: {
            self.readingListsFunnel.logArticleSaveInCurrentArticle(self.articleURL)
        })
        activities.append(readingListActivity)

        if let text = selectedText, !text.isEmpty {
            let shareAFactActivity = CustomShareActivity(title: "Share-a-fact", imageName: "share-a-fact", action: {
                self.shareAFact(with: text)
            })
            activities.append(shareAFactActivity)
        }

        guard let vc = sharingActivityViewController(with: selectedText, button: toolbarController.shareButton, customActivities: activities) else {
            return
        }
        present(vc, animated: true)
    }
    
    func sharingActivityViewController(with textSnippet: String?, button: UIBarButtonItem, customActivities: [UIActivity]?) -> ShareActivityController? {
        let vc: ShareActivityController
        let textActivitySource = WMFArticleTextActivitySource(article: article, shareText: textSnippet)
        if let customActivities = customActivities, !customActivities.isEmpty {
            vc = ShareActivityController(customActivities: customActivities, article: article, textActivitySource: textActivitySource)
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
    
    
    func addToReadingListActivity(with presenter: UIViewController, eventLogAction: @escaping () -> Void) -> UIActivity {
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
