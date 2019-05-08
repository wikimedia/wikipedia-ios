import UIKit

fileprivate class View: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 400)
    }
}

class InsertLinkInputViewController: UIInputViewController {
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
        return searchViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        let navigationController = UINavigationController(rootViewController: searchViewController)
        navigationController.isNavigationBarHidden = true
        wmf_add(childController: navigationController, andConstrainToEdgesOfContainerView: view)
    }

    override func loadView() {
        let view = View()
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view = view
    }
}
