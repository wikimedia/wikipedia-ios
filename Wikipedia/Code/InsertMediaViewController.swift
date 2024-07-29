protocol InsertMediaViewControllerDelegate: AnyObject {
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didTapCloseButton button: UIBarButtonItem)
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didPrepareWikitextToInsert wikitext: String)
}

final class InsertMediaViewController: ViewController {
    private let selectedImageViewController = InsertMediaSelectedImageViewController()
    private let searchViewController: InsertMediaSearchViewController
    private let searchResultsCollectionViewController = InsertMediaSearchResultsCollectionViewController()

    weak var delegate: InsertMediaViewControllerDelegate?
    private let siteURL: URL

    init(articleTitle: String?, siteURL: URL) {
        searchViewController = InsertMediaSearchViewController(articleTitle: articleTitle, siteURL: siteURL)
        searchResultsCollectionViewController.delegate = selectedImageViewController
        self.siteURL = siteURL
        super.init()
        selectedImageViewController.delegate = self
        searchViewController.progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        searchViewController.delegate = self
        searchViewController.searchBarDelegate = self
        searchResultsCollectionViewController.scrollDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var nextButton: UIBarButtonItem = {
        let nextButton = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(goToMediaSettings(_:)))
        nextButton.isEnabled = false
        return nextButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        title = CommonStrings.insertMediaTitle
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = nextButton
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.accessibilityBackTitle, style: .plain, target: nil, action: nil)
        navigationBar.displayType = .modal
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.isExtendedViewHidingEnabled = true
        navigationBar.isTopSpacingHidingEnabled = false

        addChild(selectedImageViewController)
        navigationBar.addUnderNavigationBarView(selectedImageViewController.view, shouldIgnoreSafeArea: true)
        selectedImageViewController.didMove(toParent: self)

        addChild(searchViewController)
        navigationBar.addExtendedNavigationBarView(searchViewController.view)
        searchViewController.didMove(toParent: self)

        wmf_add(childController: searchResultsCollectionViewController, andConstrainToEdgesOfContainerView: view)

        additionalSafeAreaInsets = searchResultsCollectionViewController.additionalSafeAreaInsets
        scrollView = searchResultsCollectionViewController.collectionView
    }

    private var selectedImageViewHeightConstraint: NSLayoutConstraint?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if selectedImageViewHeightConstraint == nil {
            selectedImageViewHeightConstraint = selectedImageViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
            selectedImageViewHeightConstraint?.isActive = true
        }
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
        delegate?.insertMediaViewController(self, didTapCloseButton: sender)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        selectedImageViewController.apply(theme: theme)
        searchViewController.apply(theme: theme)
        searchResultsCollectionViewController.apply(theme: theme)
        closeButton.tintColor = theme.colors.primaryText
        nextButton.tintColor = theme.colors.link
    }

    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        searchResultsCollectionViewController.scrollViewInsetsDidChange()
    }

    override func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        guard !isAnimatingSearchBarState else {
            return
        }
        super.keyboardDidChangeFrame(from: oldKeyboardFrame, newKeyboardFrame: newKeyboardFrame)
    }

    override func accessibilityPerformEscape() -> Bool {
        delegate?.insertMediaViewController(self, didTapCloseButton: closeButton)
        return true
    }

    var isAnimatingSearchBarState: Bool = false
    
    override var shouldAnimateWhileUpdatingScrollViewInsets: Bool {
        return true
    }

    func focusSearch(_ focus: Bool, animated: Bool = true, additionalAnimations: (() -> Void)? = nil) {
        useNavigationBarVisibleHeightForScrollViewInsets = focus
        navigationBar.isAdjustingHidingFromContentInsetChangesEnabled = true
        let completion = { (finished: Bool) in
            self.isAnimatingSearchBarState = false
            self.useNavigationBarVisibleHeightForScrollViewInsets = focus
        }

        let animations = {
            let underBarViewPercentHidden: CGFloat
            let extendedViewPercentHidden: CGFloat
            if let scrollView = self.scrollView, scrollView.isAtTop, !focus {
                underBarViewPercentHidden = 0
                extendedViewPercentHidden = 0
            } else {
                underBarViewPercentHidden = 1
                extendedViewPercentHidden = focus ? 0 : 1
            }
            self.navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, topSpacingPercentHidden: 0, animated: false)
            self.searchViewController.searchBar.setShowsCancelButton(focus, animated: animated)
            additionalAnimations?()
            self.view.layoutIfNeeded()
            self.updateScrollViewInsets()
        }
        guard animated else {
            animations()
            completion(true)
            return
        }
        isAnimatingSearchBarState = true
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, animations: animations, completion: completion)
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
        guard !isAnimatingSearchBarState else {
            return
        }
        scrollViewDidScroll(scrollView)
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewWillBeginDragging scrollView: UIScrollView) {
        scrollViewWillBeginDragging(scrollView)
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewWillEndDragging scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidEndDecelerating scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(scrollView)
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidEndScrollingAnimation scrollView: UIScrollView) {
        scrollViewDidEndScrollingAnimation(scrollView)
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewShouldScrollToTop scrollView: UIScrollView) -> Bool {
        return scrollViewShouldScrollToTop(scrollView)
    }

    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidScrollToTop scrollView: UIScrollView) {
        scrollViewDidScrollToTop(scrollView)
    }
}

extension InsertMediaViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewController.search(for: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        unfocusSearch {
            searchBar.endEditing(true)
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        navigationBar.isUnderBarViewHidingEnabled = false
        navigationBar.isExtendedViewHidingEnabled = false
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard !isAnimatingSearchBarState else {
            return
        }
        unfocusSearch {
            searchBar.endEditing(true)
            searchBar.text = nil
        }
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.isExtendedViewHidingEnabled = true
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        guard !isAnimatingSearchBarState else {
            return false
        }
        focusSearch(true)
        return true
    }

    private func unfocusSearch(additionalAnimations: (() -> Void)? = nil) {
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.isExtendedViewHidingEnabled = true
        focusSearch(false, additionalAnimations: additionalAnimations)
    }
}

extension InsertMediaViewController: EditingFlowViewController {
    
}

extension InsertMediaViewController: InsertMediaSettingsViewControllerDelegate {
    func insertMediaSettingsViewControllerDidTapProgress(imageWikitext: String, caption: String?, altText: String?, localizedFileTitle: String) {
        delegate?.insertMediaViewController(self, didPrepareWikitextToInsert: imageWikitext)
    }
}
