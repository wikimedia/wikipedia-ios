protocol MediaWizardControllerDelegate: AnyObject {
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didPrepareViewController viewController: UIViewController)
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didTapCloseButton button: UIBarButtonItem)
}

final class MediaWizardController: NSObject {
    private let articleTitle: String?
    private let siteURL: URL?
    private let searchFetcher: WMFSearchFetcher
    private let imageInfoFetcher: MWKImageInfoFetcher

    weak var delegate: MediaWizardControllerDelegate?

    private let searchResultsCollectionViewController = InsertMediaSearchResultsCollectionViewController()

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var nextButton: UIBarButtonItem = {
        return UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(goToMediaSettings(_:)))
    }()

    private lazy var tabbedViewController: TabbedViewController = {
        let searchView = SearchView(searchBarDelegate: self, placeholder: articleTitle)
        return TabbedViewController(viewControllers: [searchResultsCollectionViewController, UploadMediaViewController()], extendedViews: [searchView])
    }()

    init(articleTitle: String?, siteURL: URL?) {
        self.articleTitle = articleTitle
        self.siteURL = siteURL ?? Configuration.current.commonsAPIURLComponents(with: nil).url
        self.searchFetcher = WMFSearchFetcher()
        self.imageInfoFetcher = MWKImageInfoFetcher()
        super.init()
    }

    func prepare(with theme: Theme) {
        if let articleTitle = articleTitle {
            search(for: articleTitle)
        }
        prepareUI(with: theme)
    }

    private func prepareUI(with theme: Theme) {
        let insertMediaImageViewController = InsertMediaImageViewController(nibName: "InsertMediaImageViewController", bundle: nil)
        insertMediaImageViewController.delegate = self
        searchResultsCollectionViewController.delegate = insertMediaImageViewController

        let tabbedNavigationController = WMFThemeableNavigationController(rootViewController: tabbedViewController, theme: theme)
        tabbedNavigationController.isNavigationBarHidden = true

        let verticallySplitViewController = VerticallySplitViewController(topViewController: insertMediaImageViewController, bottomViewController: tabbedNavigationController)
        verticallySplitViewController.title = WMFLocalizedString("insert-media-title", value: "Insert media", comment: "Title for the view in charge of inserting media into an article")
        closeButton.tintColor = theme.colors.chromeText
        nextButton.tintColor = theme.colors.link
        nextButton.isEnabled = false
        verticallySplitViewController.navigationItem.leftBarButtonItem = closeButton
        verticallySplitViewController.navigationItem.rightBarButtonItem = nextButton
        let navigationController = WMFThemeableNavigationController(rootViewController: verticallySplitViewController, theme: theme)
        delegate?.mediaWizardController(self, didPrepareViewController: navigationController)
    }

    private func search(for searchTerm: String) {
        tabbedViewController.progressController.start()
        let failure = { (error: Error) in
            let nserror = error as NSError
            guard nserror.code != NSURLErrorCancelled else {
                return
            }
            DispatchQueue.main.async {
                self.searchResultsCollectionViewController.emptyViewType = nserror.wmf_isNetworkConnectionError() ? .noInternetConnection : .noSearchResults
                self.searchResultsCollectionViewController.searchResults = []
                self.tabbedViewController.progressController.stop()
            }
        }
        let searchResults: (WMFSearchResults) -> [InsertMediaSearchResult] = { (results: WMFSearchResults) in
            guard let results = results.results else {
                return []
            }
            return results.compactMap { (result: MWKSearchResult) in
                guard
                    let displayTitle = result.displayTitle,
                    let thumbnailURL = result.thumbnailURL
                else {
                    return nil
                }
                return InsertMediaSearchResult(displayTitle: displayTitle, thumbnailURL: thumbnailURL)
            }
        }
        let success = { (results: WMFSearchResults) in
            let searchResults = searchResults(results)
            if !searchTerm.wmf_hasNonWhitespaceText {
                DispatchQueue.main.async {
                    self.searchResultsCollectionViewController.emptyViewType = .none
                    self.tabbedViewController.progressController.stop()
                }
            }
            DispatchQueue.main.async {
                self.searchResultsCollectionViewController.searchResults = searchResults
            }
            var cancelledImageInfoFetch = false
            for (index, searchResult) in searchResults.enumerated() {
                guard !cancelledImageInfoFetch else {
                    DispatchQueue.main.async {
                        self.tabbedViewController.progressController.stop()
                    }
                    return
                }
                guard searchResult.imageInfo == nil else {
                    continue
                }
                self.imageInfoFetcher.fetchGalleryInfo(forImage: searchResult.displayTitle, fromSiteURL: self.siteURL, failure: { error in
                    let nserror = error as NSError
                    if nserror.code == NSURLErrorCancelled {
                        cancelledImageInfoFetch = true
                    } else {
                        assertionFailure(error.localizedDescription)
                    }
                }, success: { result in
                    DispatchQueue.main.async {
                        if index == searchResults.endIndex - 1 {
                            self.tabbedViewController.progressController.finish()
                        }
                        self.searchResultsCollectionViewController.setImageInfo(result as? MWKImageInfo, for: searchResult, at: index)
                    }
                })
            }
        }
        searchFetcher.fetchFiles(forSearchTerm: searchTerm, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: false, appendToPreviousResults: nil, failure: failure) { results in
            if let resultsArray = results.results {
                if resultsArray.isEmpty {
                    self.searchFetcher.fetchFiles(forSearchTerm: searchTerm, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: failure, success: success)
                } else if resultsArray.count < 12 {
                    DispatchQueue.main.async {
                        self.searchResultsCollectionViewController.searchResults = searchResults(results)
                    }
                    self.searchFetcher.fetchFiles(forSearchTerm: searchTerm, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: failure, success: success)
                } else {
                    success(results)
                }
            } else {
                self.searchFetcher.fetchFiles(forSearchTerm: searchTerm, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: failure, success: success)
            }
        }
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.mediaWizardController(self, didTapCloseButton: sender)
    }

    @objc private func goToMediaSettings(_ sender: UIBarButtonItem) {

    }
}

final fileprivate class SearchView: UIView, Themeable {
    private let searchBar: UISearchBar

    init(searchBarDelegate: UISearchBarDelegate, placeholder: String?) {
        searchBar = UISearchBar()
        searchBar.placeholder = placeholder ?? CommonStrings.searchTitle
        searchBar.delegate = searchBarDelegate
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = false
        super.init(frame: .zero)
        wmf_addSubview(searchBar, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: Theme) {
        searchBar.apply(theme: theme)
    }
}

extension MediaWizardController: InsertMediaImageViewControllerDelegate {
    func insertMediaImageViewController(_ insertMediaImageViewController: InsertMediaImageViewController, didSetSelectedImage image: UIImage?, from searchResult: InsertMediaSearchResult) {
        nextButton.isEnabled = true
    }
}

extension MediaWizardController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchFetcher.cancelAllFetches()
        imageInfoFetcher.cancelAllFetches()
        search(for: searchText)
    }
}
