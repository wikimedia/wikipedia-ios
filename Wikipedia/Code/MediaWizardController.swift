protocol MediaWizardControllerDelegate: AnyObject {
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didPrepareViewController viewController: UIViewController)
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didTapCloseButton button: UIBarButtonItem)
}

final class MediaWizardController: NSObject {
    private let searchFetcher = WMFSearchFetcher()
    private let imageInfoFetcher = MWKImageInfoFetcher()

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

    func prepare(for articleTitle: String?, from siteURL: URL?, with theme: Theme) {
        prepareSearchResults(for: articleTitle, from: siteURL)
        prepareUI(with: theme, placeholder: articleTitle)
    }

    private func prepareUI(with theme: Theme, placeholder: String?) {
        let insertMediaImageViewController = InsertMediaImageViewController(nibName: "InsertMediaImageViewController", bundle: nil)
        searchResultsCollectionViewController.delegate = insertMediaImageViewController
        
        let searchView = SearchView(searchBarDelegate: searchResultsCollectionViewController, placeholder: placeholder)
        searchView.apply(theme: theme)

        let tabbedViewController = TabbedViewController(viewControllers: [searchResultsCollectionViewController, UploadMediaViewController()], extendedViews: [searchView])
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

    private func prepareSearchResults(for articleTitle: String?, from siteURL: URL?) {
        guard
            let articleTitle = articleTitle
        else {
            return
        }
        let progressController = searchResultsCollectionViewController.fakeProgressController
        progressController.start()
        let failure = { (error: Error) in
            DispatchQueue.main.async {
                self.searchResultsCollectionViewController.emptyViewType = (error as NSError).wmf_isNetworkConnectionError() ? .noInternetConnection : .noSearchResults
                self.searchResultsCollectionViewController.searchResults = []
                progressController.stop()
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
            DispatchQueue.main.async {
                self.searchResultsCollectionViewController.searchResults = searchResults
            }
            for (index, searchResult) in searchResults.enumerated() {
                guard searchResult.imageInfo == nil else {
                    continue
                }
                let url = siteURL ?? Configuration.current.commonsAPIURLComponents(with: nil).url
                self.imageInfoFetcher.fetchGalleryInfo(forImage: searchResult.displayTitle, fromSiteURL: url, failure: { error in
                    assertionFailure()
                }, success: { result in
                    DispatchQueue.main.async {
                        self.searchResultsCollectionViewController.setImageInfo(result as? MWKImageInfo, for: searchResult, at: index)
                    }
                })
            }
//            if let names = results.results?.compactMap({ $0.displayTitle }) {
//                self.imageInfoFetcher.fetchGalleryInfo(forImageFiles: names, fromSiteURL: siteURL, success: { result in
//                    guard let imageInfoResults = result as? [MWKImageInfo] else {
//                        assertionFailure()
//                        return
//                    }
//                    DispatchQueue.main.async {
//                        self.searchResultsCollectionViewController.imageInfoResults = imageInfoResults
//                        progressController.finish()
//                    }
//                }, failure: { error in
//                    assertionFailure(error!.localizedDescription)
//                })
//            } else {
//                DispatchQueue.main.async {
//                    progressController.finish()
//                }
//            }
        }
        searchFetcher.fetchFiles(forSearchTerm: articleTitle, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: false, appendToPreviousResults: nil, failure: failure) { results in
            if let resultsArray = results.results {
                if resultsArray.isEmpty {
                    self.searchFetcher.fetchFiles(forSearchTerm: articleTitle, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: failure, success: success)
                } else if resultsArray.count < 12 {
                    DispatchQueue.main.async {
                        self.searchResultsCollectionViewController.searchResults = searchResults(results)
                    }
                    self.searchFetcher.fetchFiles(forSearchTerm: articleTitle, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: failure, success: success)
                }
            } else {
                self.searchFetcher.fetchFiles(forSearchTerm: articleTitle, resultLimit: WMFMaxSearchResultLimit, fullTextSearch: true, appendToPreviousResults: results, failure: failure, success: success)
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
