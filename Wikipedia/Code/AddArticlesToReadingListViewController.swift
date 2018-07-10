import UIKit

protocol AddArticlesToReadingListDelegate: NSObjectProtocol {
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, willBeDismissed: Bool)
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
}

extension AddArticlesToReadingListDelegate where Self: EditableCollection {
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, willBeDismissed: Bool) {
        editController.close()
    }
    
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        editController.close()
    }
}

@objc(WMFAddArticlesToReadingListViewController)
class AddArticlesToReadingListViewController: ViewController {
    
    private let dataStore: MWKDataStore
    private let articles: [WMFArticle]
    public let moveFromReadingList: ReadingList?

    private var readingListsViewController: ReadingListsViewController?
    public weak var delegate: AddArticlesToReadingListDelegate?
    
    @objc var eventLogAction: (() -> Void)?

    @objc public init(with dataStore: MWKDataStore, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil, theme: Theme) {
        self.dataStore = dataStore
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        super.init()
        self.theme = theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
        delegate?.addArticlesToReadingList(self, willBeDismissed: true)
    }
    
    @objc private func addButtonPressed() {
        readingListsViewController?.createReadingList(with: articles, moveFromReadingList: moveFromReadingList)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(closeButtonPressed))
        let title = moveFromReadingList != nil ? WMFLocalizedString("move-articles-to-reading-list", value:"Move {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of moving articles to a reading list - %1$@ is replaced with the number of articles to move") : WMFLocalizedString("add-articles-to-reading-list", value:"Add {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add")
        navigationItem.title = String.localizedStringWithFormat(title, articles.count)
        navigationBar.displayType = .modal
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true

        readingListsViewController = ReadingListsViewController(with: dataStore, articles: articles)
        guard let readingListsViewController = readingListsViewController else {
            return
        }
        readingListsViewController.apply(theme: theme)
        readingListsViewController.createNewReadingListButtonView.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        navigationBar.addUnderNavigationBarView(readingListsViewController.createNewReadingListButtonView)
        addChildViewController(readingListsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(readingListsViewController.view)
        readingListsViewController.didMove(toParentViewController: self)
        readingListsViewController.delegate = self
        apply(theme: theme)
    }
}

extension AddArticlesToReadingListViewController: ReadingListsViewControllerDelegate {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        if let moveFromReadingList = moveFromReadingList {
            do {
                try dataStore.readingListsController.remove(articles: articles, readingList: moveFromReadingList)
            } catch let error {
                DDLogError("Error removing articles after move: \(error)")
            }
        }
        delegate?.addArticlesToReadingList(self, didAddArticles: articles, to: readingList)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.dismiss(animated: true, completion: nil)
        }
        eventLogAction?()
    }
}
