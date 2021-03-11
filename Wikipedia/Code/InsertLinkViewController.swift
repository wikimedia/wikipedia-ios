import UIKit

protocol InsertLinkViewControllerDelegate: AnyObject {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?)
}

class InsertLinkViewController: UIViewController {
    weak var delegate: InsertLinkViewControllerDelegate?
    private var theme = Theme.standard
    private let dataStore: MWKDataStore
    typealias Link = SectionEditorWebViewMessagingController.Link
    private let link: Link
    private let siteURL: URL?

    init(link: Link, siteURL: URL?, dataStore: MWKDataStore) {
        self.link = link
        self.siteURL = siteURL
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var searchViewController: SearchViewController = {
        let searchViewController = SearchViewController()
        searchViewController.dataStore = dataStore
        searchViewController.siteURL = siteURL
        searchViewController.searchTerm = link.page
        searchViewController.areRecentSearchesEnabled = true
        searchViewController.shouldBecomeFirstResponder = true
        searchViewController.dataStore = MWKDataStore.shared()
        searchViewController.shouldShowCancelButton = false
        searchViewController.delegate = self
        searchViewController.delegatesSelection = true
        searchViewController.showLanguageBar = false
		searchViewController.updateRecentlySearchedVisibility(searchText: nil)
        return searchViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.insertLinkTitle
        navigationItem.leftBarButtonItem = closeButton
        let navigationController = WMFThemeableNavigationController(rootViewController: searchViewController)
        navigationController.isNavigationBarHidden = true
        wmf_add(childController: navigationController, andConstrainToEdgesOfContainerView: view)
        apply(theme: theme)
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.insertLinkViewController(self, didTapCloseButton: sender)
    }

    override func accessibilityPerformEscape() -> Bool {
        delegate?.insertLinkViewController(self, didTapCloseButton: closeButton)
        return true
    }
}

extension InsertLinkViewController: ArticleCollectionViewControllerDelegate {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWith articleURL: URL, at indexPath: IndexPath) {
        guard let title = articleURL.wmf_title else {
            return
        }
        delegate?.insertLinkViewController(self, didInsertLinkFor: title, withLabel: nil)
    }
}

extension InsertLinkViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.inputAccessoryBackground
        view.layer.shadowColor = theme.colors.shadow.cgColor
        closeButton.tintColor = theme.colors.primaryText
        searchViewController.apply(theme: theme)
    }
}
