import WMFComponents

protocol InsertMediaViewControllerDelegate: AnyObject {
    func didTapCloseButton(insertMediaViewController: InsertMediaViewController)
    func didPrepareWikitextToInsert(wikitext: String, insertMediaViewController: InsertMediaViewController)
}

final class InsertMediaViewController: ThemeableViewController, WMFNavigationBarConfiguring {
    private let selectedImageViewController = InsertMediaSelectedImageViewController()
    private let searchViewController: InsertMediaSearchViewController
    private let searchResultsCollectionViewController = InsertMediaSearchResultsCollectionViewController()

    weak var delegate: InsertMediaViewControllerDelegate?
    private let siteURL: URL

    init(articleTitle: String?, siteURL: URL) {
        searchViewController = InsertMediaSearchViewController(articleTitle: articleTitle, siteURL: siteURL)
        searchResultsCollectionViewController.delegate = selectedImageViewController
        self.siteURL = siteURL
        super.init(nibName: nil, bundle: nil)
        selectedImageViewController.delegate = self
        searchViewController.delegate = self
        searchViewController.searchBarDelegate = self
        searchResultsCollectionViewController.scrollDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var nextButton: UIBarButtonItem = {
        let nextButton = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(goToMediaSettings(_:)))
        nextButton.isEnabled = false
        return nextButton
    }()

    private var selectedImageTopConstraint: NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(searchResultsCollectionViewController)
        searchResultsCollectionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultsCollectionViewController.view)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: searchResultsCollectionViewController.view.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: searchResultsCollectionViewController.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: searchResultsCollectionViewController.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: searchResultsCollectionViewController.view.bottomAnchor)
        ])
        searchResultsCollectionViewController.didMove(toParent: self)

        addChild(selectedImageViewController)
        selectedImageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectedImageViewController.view)
        let selectedImageTopConstraint = view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: selectedImageViewController.view.topAnchor)
        self.selectedImageTopConstraint = selectedImageTopConstraint
        NSLayoutConstraint.activate([
            selectedImageTopConstraint,
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: selectedImageViewController.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: selectedImageViewController.view.trailingAnchor),
            selectedImageViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        ])
        selectedImageViewController.didMove(toParent: self)

        addChild(searchViewController)
        searchViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchViewController.view)
        NSLayoutConstraint.activate([
            selectedImageViewController.view.bottomAnchor.constraint(equalTo: searchViewController.view.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: searchViewController.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: searchViewController.view.trailingAnchor)
        ])
        searchViewController.didMove(toParent: self)

        determineResultsContentInset()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        determineResultsContentInset()
    }
    
    private func determineResultsContentInset() {
        view.setNeedsLayout()
        selectedImageViewController.view.layoutIfNeeded()
        searchViewController.view.layoutIfNeeded()
        
        searchResultsCollectionViewController.collectionView.contentInset = UIEdgeInsets(top: selectedImageViewController.view.frame.height + searchViewController.view.frame.height, left: 0, bottom: 0, right: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
    }

    private var isDisappearing = false

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isDisappearing = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isDisappearing = false
    }

    private var isTransitioningToNewCollection = false

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        isTransitioningToNewCollection = true
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
        }) { _ in
            self.isTransitioningToNewCollection = false
        }
    }

    private func configureNavigationBar() {
        
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.insertMediaTitle, customView: nil, alignment: .centerCompact)
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(delegateCloseButtonTap(_:)), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil,searchBarConfig: nil, hideNavigationBarOnScroll: false)
        
        navigationItem.rightBarButtonItem = nextButton
    }
    
    @objc private func goToMediaSettings(_ sender: UIBarButtonItem) {
        guard
            let navigationController = navigationController,
            let selectedSearchResult = selectedImageViewController.searchResult,
            let image = selectedImageViewController.image ?? searchResultsCollectionViewController.selectedImage
        else {
            assertionFailure("Selected image and search result should be set by now")
            return
        }
        let settingsViewController = InsertMediaSettingsViewController(image: image, searchResult: selectedSearchResult, fromImageRecommendations: false, delegate: self, imageRecLoggingDelegate: nil, theme: theme, siteURL: siteURL)

        navigationController.pushViewController(settingsViewController, animated: true)
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.didTapCloseButton(insertMediaViewController: self)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        selectedImageViewController.apply(theme: theme)
        searchViewController.apply(theme: theme)
        searchResultsCollectionViewController.apply(theme: theme)
        nextButton.tintColor = theme.colors.link
    }
    
    override func accessibilityPerformEscape() -> Bool {
        delegate?.didTapCloseButton(insertMediaViewController: self)
        return true
    }
}

extension InsertMediaViewController: InsertMediaSearchViewControllerDelegate {
    func insertMediaSearchViewController(_ insertMediaSearchViewController: InsertMediaSearchViewController, didFind searchResults: [InsertMediaSearchResult]) {
        searchResultsCollectionViewController.emptyViewType = .noSearchResults
        searchResultsCollectionViewController.searchResults = searchResults
    }

    func insertMediaSearchViewController(_ insertMediaSearchViewController: InsertMediaSearchViewController, didFind imageInfo: MWKImageInfo, for searchResult: InsertMediaSearchResult, at index: Int) {
        searchResultsCollectionViewController.setImageInfo(imageInfo, for: searchResult, at: index)
    }

    func insertMediaSearchViewController(_ insertMediaSearchViewController: InsertMediaSearchViewController, didFailWithError error: Error) {
        let emptyViewType: WMFEmptyViewType
        let nserror = error as NSError
        if nserror.wmf_isNetworkConnectionError() {
            emptyViewType = .noInternetConnection
        } else if nserror.domain == NSURLErrorDomain, nserror.code == NSURLErrorCancelled {
            emptyViewType = .none
        } else {
            emptyViewType = .noSearchResults
        }
        searchResultsCollectionViewController.emptyViewType = emptyViewType
        searchResultsCollectionViewController.searchResults = []
    }
}

extension InsertMediaViewController: InsertMediaSelectedImageViewControllerDelegate {
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, willSetSelectedImageFrom searchResult: InsertMediaSearchResult) {
        nextButton.isEnabled = false
    }

    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, didSetSelectedImage selectedImage: UIImage?, from searchResult: InsertMediaSearchResult) {
        nextButton.isEnabled = true
    }
}

extension InsertMediaViewController: InsertMediaSearchResultsCollectionViewControllerScrollDelegate {
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidScroll scrollView: UIScrollView) {
        
        let delta = scrollView.contentInset.top - (scrollView.contentOffset.y * -1)
        selectedImageTopConstraint?.constant = delta
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewWillBeginDragging scrollView: UIScrollView) {
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewWillEndDragging scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidEndDecelerating scrollView: UIScrollView) {
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidEndScrollingAnimation scrollView: UIScrollView) {
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewShouldScrollToTop scrollView: UIScrollView) -> Bool {
        return true
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidScrollToTop scrollView: UIScrollView) {
    }
}

extension InsertMediaViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewController.search(for: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.text = nil
    }
}

extension InsertMediaViewController: EditingFlowViewController {
    
}

extension InsertMediaViewController: InsertMediaSettingsViewControllerDelegate {
    func insertMediaSettingsViewControllerDidTapProgress(imageWikitext: String, caption: String?, altText: String?, localizedFileTitle: String) {
        delegate?.didPrepareWikitextToInsert(wikitext: imageWikitext, insertMediaViewController: self)
    }
}
