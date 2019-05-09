import UIKit

protocol InsertLinkViewControllerDelegate: AnyObject {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?)
}
class InsertLinkViewController: UIViewController {
    weak var delegate: InsertLinkViewControllerDelegate?
    private var theme = Theme.standard

    typealias Link = SectionEditorWebViewMessagingController.Link

    var link: Link? {
        didSet {
            guard let link = link else {
                return
            }
            searchViewController.searchTerm = link.page
            searchViewController.search()
        }
    }

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var searchViewController: SearchViewController = {
        let searchViewController = SearchViewController()
        searchViewController.areRecentSearchesEnabled = false
        searchViewController.shouldBecomeFirstResponder = true
        #warning("Inject dataStore")
        searchViewController.dataStore = SessionSingleton.sharedInstance()?.dataStore
        searchViewController.shouldShowCancelButton = false
        searchViewController.delegate = self
        searchViewController.delegatesSelection = true
        searchViewController.showLanguageBar = false
        return searchViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Insert link"
        navigationItem.rightBarButtonItem = closeButton
        let navigationController = WMFThemeableNavigationController(rootViewController: searchViewController)
        navigationController.isNavigationBarHidden = true
        wmf_add(childController: navigationController, andConstrainToEdgesOfContainerView: view)
        addTopShadow()
        apply(theme: theme)
    }

    private func addTopShadow() {
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1.0
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.insertLinkViewController(self, didTapCloseButton: sender)
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
    }
}
