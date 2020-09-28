protocol InsertMediaSearchViewControllerDelegate: InsertMediaViewController {
    func insertMediaSearchViewController(_ insertMediaSearchViewController: InsertMediaSearchViewController, didFailWithError error: Error)
    func insertMediaSearchViewController(_ insertMediaSearchViewController: InsertMediaSearchViewController, didFind searchResults: [InsertMediaSearchResult])
    func insertMediaSearchViewController(_ insertMediaSearchViewController: InsertMediaSearchViewController, didFind imageInfo: MWKImageInfo, for searchResult: InsertMediaSearchResult, at index: Int)
}

final class InsertMediaSearchViewController: UIViewController {
    let searchBar = UISearchBar()

    private let articleTitle: String?
    private let siteURL: URL?

    var progressController: FakeProgressController!

    private let searchFetcher = WMFSearchFetcher()
    // SINGLETONTODO
    private let imageInfoFetcher = MWKImageInfoFetcher(dataStore: MWKDataStore.shared())

    weak var delegate: InsertMediaSearchViewControllerDelegate?
    weak var searchBarDelegate: UISearchBarDelegate?

    private var theme = Theme.standard

    init(articleTitle: String?, siteURL: URL?) {
        self.articleTitle = articleTitle
        self.siteURL = siteURL ?? Configuration.current.commonsAPIURLComponents(with: nil).url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let articleTitle = articleTitle {
            search(for: articleTitle, isFirstSearch: true)
        }
        searchBar.placeholder = articleTitle ?? CommonStrings.searchTitle
        searchBar.returnKeyType = .done
        searchBar.searchBarStyle = .minimal
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = searchBarDelegate
        view.wmf_addSubview(searchBar, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        apply(theme: theme)
    }

    func search(for searchTerm: String, isFirstSearch: Bool = false) {
        searchFetcher.cancelAllFetches()
        imageInfoFetcher.cancelAllFetches()
        guard searchTerm.wmf_hasNonWhitespaceText else {
            searchForArticleTitle()
            return
        }
        if isFirstSearch {
            progressController.delay = 0
        } else {
            progressController.delay = 1.0
        }
        progressController.start()
        let failure = { (error: Error) in
            DispatchQueue.main.async {
                self.progressController.stop()
                self.delegate?.insertMediaSearchViewController(self, didFailWithError: error)
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
            DispatchQueue.main.async {
                self.progressController.finish()
                self.delegate?.insertMediaSearchViewController(self, didFind: searchResults)
            }
            for (index, searchResult) in searchResults.enumerated() {
                guard searchResult.imageInfo == nil,
                    let siteURL = self.siteURL else {
                    continue
                }
                self.imageInfoFetcher.fetchGalleryInfo(forImage: searchResult.fileTitle, fromSiteURL: siteURL, failure: { error in
                }, success: { result in
                    guard let imageInfo = result as? MWKImageInfo else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.delegate?.insertMediaSearchViewController(self, didFind: imageInfo, for: searchResult, at: index)
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
                        self.delegate?.insertMediaSearchViewController(self, didFind: searchResults)
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

    func searchForArticleTitle() {
        if let articleTitle = articleTitle {
            search(for: articleTitle)
        }
    }
}

extension InsertMediaSearchViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        searchBar.apply(theme: theme)
        searchBar.tintColor = theme.colors.link
    }
}
