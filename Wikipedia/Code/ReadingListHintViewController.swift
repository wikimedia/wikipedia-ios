@objc(WMFReadingListHintViewController)
class ReadingListHintViewController: HintViewController {
    var dataStore: MWKDataStore?
    
    var article: WMFArticle? {
        didSet {
            guard viewIfLoaded != nil else {
                return
            }
            guard article != oldValue else {
                return
            }
            defaultLabel.text = hintButtonTitle
        }
    }
    
    private var hintButtonTitle: String {
        var maybeArticleTitle: String? = nil
        if let article = article {
            if let displayTitle = article.displayTitle, displayTitle.wmf_hasNonWhitespaceText {
                maybeArticleTitle = displayTitle
            } else if let articleURL = article.url, let title = articleURL.wmf_title {
                maybeArticleTitle = title
            }
        }
        
        guard let articleTitle = maybeArticleTitle, articleTitle.wmf_hasNonWhitespaceText else {
            return WMFLocalizedString("reading-list-add-generic-hint-title", value: "Add this article to a reading list?", comment: "Title of the reading list hint that appears after an article is saved.")
        }
        
        return String.localizedStringWithFormat(WMFLocalizedString("reading-list-add-hint-title", value: "Add “%1$@” to a reading list?", comment: "Title of the reading list hint that appears after an article is saved. %1$@ will be replaced with the saved article title"), "\(articleTitle)")
    }

    open override func configureSubviews() {
        defaultImageView.image = #imageLiteral(resourceName: "add-to-list")
        confirmationAccessoryButton.setImage(#imageLiteral(resourceName: "chevron-right.pdf"), for: .normal)
        defaultLabel.text = hintButtonTitle
    }

    private var readingList: ReadingList?
    private var themeableNavigationController: WMFThemeableNavigationController?

    @IBAction open override func performDefaultAction(sender: Any) {
        guard let article = article, let dataStore = dataStore else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: nil, theme: theme)
        addArticlesToReadingListViewController.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }

    @IBAction open override func performConfirmationAction(sender: Any) {
        guard let readingList = readingList, let dataStore = dataStore else {
            return
        }
        let readingListDetailViewController = ReadingListDetailViewController(for: readingList, with: dataStore, displayType: .modal)
        readingListDetailViewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: readingListDetailViewController, theme: theme)
        themeableNavigationController = navigationController
        present(navigationController, animated: true) {
            self.delegate?.hintViewControllerDidPeformConfirmationAction(self)
        }
    }

    @objc private func dismissReadingListDetailViewController() {
        themeableNavigationController?.dismiss(animated: true) // can this be dismissed in a different way?
    }
}

extension ReadingListHintViewController: AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        guard let name = readingList.name else {
            return
        }
        if let imageURL = articles.first?.imageURL(forWidth: traitCollection.wmf_nearbyThumbnailWidth) {
            confirmationImageView.isHidden = false
            confirmationImageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
        } else {
            confirmationImageView.isHidden = true
        }
        self.readingList = readingList
        let title = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-article-added-confirmation", value: "Article added to “%1$@”", comment: "Confirmation shown after the user adds an article to a list. %1$@ will be replaced with the name of the list the article was added to."), name)
        confirmationLabel.text = title
        viewType = .confirmation
    }
    
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        delegate?.hintViewControllerDidFailToCompleteDefaultAction(self)
    }
}
