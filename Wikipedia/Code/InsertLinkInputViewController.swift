import UIKit

fileprivate class View: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 400)
    }
}

class InsertLinkInputViewController: UIInputViewController {
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

    private lazy var searchViewController: SearchViewController = {
        let searchViewController = SearchViewController()
        searchViewController.areRecentSearchesEnabled = false
        searchViewController.shouldBecomeFirstResponder = true
        #warning("Inject dataStore")
        searchViewController.dataStore = SessionSingleton.sharedInstance()?.dataStore
        searchViewController.shouldShowCancelButton = false
        searchViewController.delegate = self
        searchViewController.delegatesSelection = true
        return searchViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let navigationController = UINavigationController(rootViewController: searchViewController)
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

    override func loadView() {
        let view = View()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }
}

extension InsertLinkInputViewController: ArticleCollectionViewControllerDelegate {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWith articleURL: URL, at indexPath: IndexPath) {
        //
    }
}

extension InsertLinkInputViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.inputAccessoryBackground
        view.layer.shadowColor = theme.colors.shadow.cgColor
    }
}
