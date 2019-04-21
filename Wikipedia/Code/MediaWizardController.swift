protocol MediaWizardControllerDelegate: AnyObject {
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didPrepareViewController viewController: UIViewController)
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didTapCloseButton button: UIBarButtonItem)
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didPrepareWikitextToInsert wikitext: String)
}

final class MediaWizardController: NSObject {
    private let articleTitle: String?
    private let siteURL: URL?
    private let searchFetcher: WMFSearchFetcher
    private let imageInfoFetcher: MWKImageInfoFetcher

    private var theme: Theme

    weak var delegate: MediaWizardControllerDelegate?

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var nextButton: UIBarButtonItem = {
        return UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(goToMediaSettings(_:)))
    }()

    private lazy var imageViewController: InsertMediaImageViewController = {
        let imageViewController = InsertMediaImageViewController.fromNib()
        imageViewController.delegate = self
        return imageViewController
    }()

    private let searchResultsCollectionViewController = InsertMediaSearchResultsCollectionViewController()

    private lazy var tabbedViewController: TabbedViewController = {
        let searchView = SearchView(searchBarDelegate: self, placeholder: articleTitle)
        return TabbedViewController(viewControllers: [searchResultsCollectionViewController], extendedViews: [searchView])
    }()

    private lazy var verticallySplitViewController: VerticallySplitViewController = {
        let tabbedNavigationController = WMFThemeableNavigationController(rootViewController: tabbedViewController, theme: theme)
        tabbedNavigationController.isNavigationBarHidden = true
        let verticallySplitViewController = VerticallySplitViewController(topViewController: imageViewController, bottomViewController: tabbedNavigationController)
        verticallySplitViewController.title = WMFLocalizedString("insert-media-title", value: "Insert media", comment: "Title for the view in charge of inserting media into an article")
        closeButton.tintColor = theme.colors.chromeText
        nextButton.tintColor = theme.colors.link
        nextButton.isEnabled = false
        verticallySplitViewController.navigationItem.leftBarButtonItem = closeButton
        verticallySplitViewController.navigationItem.rightBarButtonItem = nextButton
        return verticallySplitViewController
    }()

    private lazy var navigationController: UINavigationController = {
        return WMFThemeableNavigationController(rootViewController: verticallySplitViewController, theme: theme)
    }()

    init(theme: Theme, articleTitle: String?, siteURL: URL?) {
        self.theme = theme
        self.articleTitle = articleTitle
        self.siteURL = siteURL ?? Configuration.current.commonsAPIURLComponents(with: nil).url
        self.searchFetcher = WMFSearchFetcher()
        self.imageInfoFetcher = MWKImageInfoFetcher()
        super.init()
    }

    func prepare() {
        if let articleTitle = articleTitle {
            search(for: articleTitle)
        }
        prepareUI()
    }

    private func prepareUI() {
        searchResultsCollectionViewController.delegate = imageViewController
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
            assert(!Thread.isMainThread)
            guard let results = results.results else {
                return []
            }
            return results.compactMap { (result: MWKSearchResult) in
                guard
                    let fileTitle = result.displayTitle,
                    let thumbnailURL = result.thumbnailURL
                else {
                    return nil
                }
                let startIndex = fileTitle.index(fileTitle.startIndex, offsetBy: 5)
                let endIndex = fileTitle.index(fileTitle.endIndex, offsetBy: -5)
                let displayTitle = String(fileTitle[startIndex...endIndex])
                return InsertMediaSearchResult(fileTitle: fileTitle, displayTitle: displayTitle, thumbnailURL: thumbnailURL)
            }
        }
        let success = { (results: WMFSearchResults) in
            assert(!Thread.isMainThread)
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
                self.imageInfoFetcher.fetchGalleryInfo(forImage: searchResult.fileTitle, fromSiteURL: self.siteURL, failure: { error in
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
                    let searchResults = searchResults(results)
                    DispatchQueue.main.async {
                        self.searchResultsCollectionViewController.searchResults = searchResults
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
        guard
            let image = imageViewController.selectedImage,
            let selectedSearchResult = imageViewController.selectedSearchResult
        else {
            assertionFailure()
            return
        }
        let settingsViewController = InsertMediaSettingsTableViewController(image: image, searchResult: selectedSearchResult)
        settingsViewController.title = WMFLocalizedString("insert-media-media-settings-title", value: "Media settings", comment: "Title for media settings view")
        let insertButton = UIBarButtonItem(title: WMFLocalizedString("insert-action-title", value: "Insert", comment: "Title for insert action"), style: .done, target: self, action: #selector(insertMedia(_:)))
        insertButton.tintColor = theme.colors.link
        settingsViewController.navigationItem.rightBarButtonItem = insertButton
        settingsViewController.apply(theme: theme)
        navigationController.pushViewController(settingsViewController, animated: true)
    }

    @objc private func insertMedia(_ sender: UIBarButtonItem) {
        guard let mediaSettingsTableViewController = navigationController.topViewController as? InsertMediaSettingsTableViewController else {
            assertionFailure()
            return
        }
        let searchResult = mediaSettingsTableViewController.searchResult
        let wikitext: String
        switch mediaSettingsTableViewController.settings {
        case nil:
            wikitext = "[[\(searchResult.fileTitle)]]"
        case let mediaSettings?:
            switch (mediaSettings.caption, mediaSettings.alternativeText) {
            case (let caption?, let alternativeText?) where caption.wmf_hasNonWhitespaceText && alternativeText.wmf_hasNonWhitespaceText:
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue) | alt= \(alternativeText) |
                \(caption)]]
                """
            case (let caption?, nil) where caption.wmf_hasNonWhitespaceText:
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue) | \(caption)]]
                """
            case (nil, let alternativeText?) where alternativeText.wmf_hasNonWhitespaceText:
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue) | alt= \(alternativeText)]]
                """
            default:
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue)]]
                """
            }
        }
        delegate?.mediaWizardController(self, didPrepareWikitextToInsert: wikitext)
    }
}

final fileprivate class SearchView: UIView, Themeable {
    private let searchBar: UISearchBar

    init(searchBarDelegate: UISearchBarDelegate, placeholder: String?) {
        searchBar = UISearchBar()
        searchBar.placeholder = placeholder ?? CommonStrings.searchTitle
        searchBar.delegate = searchBarDelegate
        searchBar.returnKeyType = .done
        searchBar.enablesReturnKeyAutomatically = false
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

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
