protocol MediaWizardControllerDelegate: AnyObject {
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didPrepareViewController viewController: UIViewController)
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didTapCloseButton button: UIBarButtonItem)
}

final class MediaWizardController: NSObject {
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

    func prepare(with theme: Theme) {
        let insertMediaImageViewController = InsertMediaImageViewController(nibName: "InsertMediaImageViewController", bundle: nil)
        let insertMediaSearchCollectionViewController = InsertMediaSearchCollectionViewController()

        let searchView = SearchView(searchBarDelegate: insertMediaSearchCollectionViewController)
        searchView.apply(theme: theme)

        let tabbedViewController = TabbedViewController(viewControllers: [insertMediaSearchCollectionViewController, UploadMediaViewController()], extendedViews: [searchView])
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

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.mediaWizardController(self, didTapCloseButton: sender)
    }

    @objc private func goToMediaSettings(_ sender: UIBarButtonItem) {

    }
}

final fileprivate class SearchView: UIView, Themeable {
    private let searchBar: UISearchBar

    init(searchBarDelegate: UISearchBarDelegate) {
        searchBar = UISearchBar()
        searchBar.placeholder = CommonStrings.searchTitle
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
