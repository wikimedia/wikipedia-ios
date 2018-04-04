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
class AddArticlesToReadingListViewController: UIViewController {
    
    private let dataStore: MWKDataStore
    private let articles: [WMFArticle]
    public let moveFromReadingList: ReadingList?
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var addButton: UIBarButtonItem?
    @IBOutlet weak var closeButton: UIBarButtonItem?
    
    private var readingListsViewController: ReadingListsViewController?
    @IBOutlet weak var containerView: UIView!
    public weak var delegate: AddArticlesToReadingListDelegate?

    private var theme: Theme
    
    @objc public init(with dataStore: MWKDataStore, articles: [WMFArticle], moveFromReadingList: ReadingList? = nil, theme: Theme) {
        self.dataStore = dataStore
        self.articles = articles
        self.theme = theme
        self.moveFromReadingList = moveFromReadingList
        super.init(nibName: "AddArticlesToReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
        delegate?.addArticlesToReadingList(self, willBeDismissed: true)
    }
    
    @IBAction func addButtonPressed() {
        readingListsViewController?.createReadingList(with: articles, moveFromReadingList: moveFromReadingList)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let title = moveFromReadingList != nil ? WMFLocalizedString("move-articles-to-reading-list", value:"Move {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of moving articles to a reading list - %1$@ is replaced with the number of articles to move") : WMFLocalizedString("add-articles-to-reading-list", value:"Add {{PLURAL:%1$d|%1$d article|%1$d articles}} to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add")
        navigationBar?.topItem?.title = String.localizedStringWithFormat(title, articles.count)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        
        readingListsViewController = ReadingListsViewController.init(with: dataStore, articles: articles)
        guard let readingListsViewController = readingListsViewController else {
            return
        }
        addChildViewController(readingListsViewController)
        readingListsViewController.view.frame = containerView.bounds
        readingListsViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(readingListsViewController.view)
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
    }
}

extension AddArticlesToReadingListViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }

        navigationBar?.barTintColor = theme.colors.chromeBackground
        navigationBar?.tintColor = theme.colors.chromeText
        navigationBar?.titleTextAttributes = theme.navigationBarTitleTextAttributes
        view.tintColor = theme.colors.link
        navigationBar?.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        view.backgroundColor = theme.colors.chromeBackground
        readingListsViewController?.apply(theme: theme)
        addButton?.tintColor = theme.colors.link
    }
    
    @objc override public var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
}
