import UIKit
import CocoaLumberjackSwift

protocol AddArticlesToReadingListDelegate: NSObjectProtocol {
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController)
    func addArticlesToReadingListDidDisappear(_ addArticlesToReadingList: AddArticlesToReadingListViewController)
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList)
}

extension AddArticlesToReadingListDelegate where Self: EditableCollection {
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        editController.close()
    }
    
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        editController.close()
    }
}

extension AddArticlesToReadingListDelegate {
    func addArticlesToReadingListDidDisappear(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {

    }
}

@objc(WMFAddArticlesToReadingListViewController)
class AddArticlesToReadingListViewController: ViewController {
    
    private let dataStore: MWKDataStore
    private let articles: [WMFArticle]
    public let moveFromReadingList: ReadingList?

    private let readingListsViewController: ReadingListsViewController
    public weak var delegate: AddArticlesToReadingListDelegate?
    
    @objc var eventLogAction: (() -> Void)?

    @objc public init(with dataStore: MWKDataStore, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil, theme: Theme) {
        self.dataStore = dataStore
        self.articles = articles
        self.moveFromReadingList = moveFromReadingList
        self.readingListsViewController = ReadingListsViewController(with: dataStore, articles: articles)
        super.init()
        self.theme = theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func closeButtonPressed() {
        dismiss(animated: true)
        delegate?.addArticlesToReadingListWillClose(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.addArticlesToReadingListDidDisappear(self)
    }
    
    @objc private func createNewReadingListButtonPressed() {
        readingListsViewController.createReadingList(with: articles, moveFromReadingList: moveFromReadingList)
    }

    override func accessibilityPerformEscape() -> Bool {
        closeButtonPressed()
        return true
    }

    private var isCreateNewReadingListButtonViewHidden: Bool = false {
        didSet {
            if isCreateNewReadingListButtonViewHidden {
                navigationBar.removeUnderNavigationBarView()
                readingListsViewController.createNewReadingListButtonView.button.removeTarget(self, action: #selector(createNewReadingListButtonPressed), for: .touchUpInside)
            } else {
                readingListsViewController.createNewReadingListButtonView.button.addTarget(self, action: #selector(createNewReadingListButtonPressed), for: .touchUpInside)
                navigationBar.addUnderNavigationBarView(readingListsViewController.createNewReadingListButtonView)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(closeButtonPressed))
        let title = moveFromReadingList != nil ? WMFLocalizedString("move-articles-to-reading-list", value:"Move {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of moving articles to a reading list - %1$@ is replaced with the number of articles to move") : WMFLocalizedString("add-articles-to-reading-list", value:"Add {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add")
        navigationItem.title = String.localizedStringWithFormat(title, articles.count)
        navigationBar.displayType = .modal
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true
        isCreateNewReadingListButtonViewHidden = readingListsViewController.isEmpty
        addChild(readingListsViewController)
        view.wmf_addSubviewWithConstraintsToEdges(readingListsViewController.view)
        readingListsViewController.didMove(toParent: self)
        readingListsViewController.delegate = self
        scrollView = readingListsViewController.scrollView
        apply(theme: theme)
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        readingListsViewController.apply(theme: theme)
    }
}

// MARK: ReadingListsViewControllerDelegate

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
            self.dismiss(animated: true)
        }
        eventLogAction?()
    }

    func readingListsViewControllerDidChangeEmptyState(_ readingListsViewController: ReadingListsViewController, isEmpty: Bool) {
        isCreateNewReadingListButtonViewHidden = isEmpty
    }
}
