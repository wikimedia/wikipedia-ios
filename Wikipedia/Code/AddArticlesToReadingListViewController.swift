import UIKit
import CocoaLumberjackSwift
import WMFComponents

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
class AddArticlesToReadingListViewController: ThemeableViewController, WMFNavigationBarConfiguring {
    
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
        self.readingListsViewController = ReadingListsViewController(with: dataStore, articles: articles, needsCreateReadingListButton: true)
        super.init(nibName: nil, bundle: nil)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(readingListsViewController)
        readingListsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(readingListsViewController.view)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: readingListsViewController.view.topAnchor),
            view.leadingAnchor.constraint(equalTo: readingListsViewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: readingListsViewController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: readingListsViewController.view.bottomAnchor)
        ])
        readingListsViewController.didMove(toParent: self)
        
        readingListsViewController.delegate = self
        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let title = moveFromReadingList != nil ? WMFLocalizedString("move-articles-to-reading-list", value:"Move {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of moving articles to a reading list - %1$@ is replaced with the number of articles to move") : WMFLocalizedString("add-articles-to-reading-list", value:"Add {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add")
        
        let titleConfig = WMFNavigationBarTitleConfig(title: String.localizedStringWithFormat(title, articles.count), customView: nil, alignment: .centerCompact)
        
        let closeButtonConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(closeButtonPressed), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        readingListsViewController.apply(theme: theme)
    }
}

// MARK: ReadingListsViewControllerDelegate

extension AddArticlesToReadingListViewController: ReadingListsViewControllerDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // no-op
    }
    
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
        // no-op
    }
}
