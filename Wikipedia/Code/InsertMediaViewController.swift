protocol InsertMediaViewControllerDelegate: AnyObject {
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didTapCloseButton button: UIBarButtonItem)
    func insertMediaViewController(_ insertMediaViewController: InsertMediaViewController, didPrepareWikitextToInsert wikitext: String)
}

final class InsertMediaViewController: ViewController {
    private let extendedViewController: InsertMediaExtendedViewController
    private let searchViewController: InsertMediaSearchViewController
    private let searchResultsCollectionViewController = InsertMediaSearchResultsCollectionViewController()

    weak var delegate: InsertMediaViewControllerDelegate?

    init(articleTitle: String?, siteURL: URL?) {
        searchViewController = InsertMediaSearchViewController(articleTitle: articleTitle, siteURL: siteURL)
        extendedViewController = InsertMediaExtendedViewController(searchViewController: searchViewController)
        searchResultsCollectionViewController.delegate = extendedViewController.selectedImageViewController
        super.init()
        extendedViewController.selectedImageViewController.delegate = self
        searchViewController.progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        searchViewController.delegate = self
        searchViewController.searchBarDelegate = self
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
        navigationBar.isExtendedViewHidingEnabled = true
        addChild(extendedViewController)
        navigationBar.addExtendedNavigationBarView(extendedViewController.view)
        extendedViewController.didMove(toParent: self)
        wmf_add(childController: searchResultsCollectionViewController, andConstrainToEdgesOfContainerView: view)
    }

    private var extendedViewHeightConstraint: NSLayoutConstraint?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if extendedViewHeightConstraint == nil {
            extendedViewHeightConstraint = extendedViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4)
            extendedViewHeightConstraint?.isActive = true
        }
    }

    @objc private func goToMediaSettings(_ sender: UIBarButtonItem) {
        guard
            let navigationController = navigationController,
            let image = extendedViewController.selectedImage,
            let selectedSearchResult = extendedViewController.selectedSearchResult
        else {
            assertionFailure("Selected image and search result should be set by now")
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
        guard let mediaSettingsTableViewController = navigationController?.topViewController as? InsertMediaSettingsTableViewController else {
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
            case (let caption?, let alternativeText?):
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue) | alt= \(alternativeText) |
                \(caption)]]
                """
            case (let caption?, nil):
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue) | \(caption)]]
                """
            case (nil, let alternativeText?):
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue) | alt= \(alternativeText)]]
                """
            default:
                wikitext = """
                [[\(searchResult.fileTitle) | \(mediaSettings.advanced.imageType.rawValue) | \(mediaSettings.advanced.imageSize.rawValue) | \(mediaSettings.advanced.imagePosition.rawValue)]]
                """
            }
        }
        delegate?.insertMediaViewController(self, didPrepareWikitextToInsert: wikitext)
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.insertMediaViewController(self, didTapCloseButton: sender)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        extendedViewController.apply(theme: theme)
        closeButton.tintColor = theme.colors.primaryText
        nextButton.tintColor = theme.colors.link
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
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, didSetSelectedImage selectedImage: UIImage?, from searchResult: InsertMediaSearchResult) {
        nextButton.isEnabled = true
    }
}

extension InsertMediaViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchViewController.search(for: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
