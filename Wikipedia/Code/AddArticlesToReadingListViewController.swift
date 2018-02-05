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
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var addButton: UIBarButtonItem?
    @IBOutlet weak var closeButton: UIBarButtonItem?
    
    private var readingListsViewController: ReadingListsViewController?
    @IBOutlet weak var containerView: UIView!
    public weak var delegate: AddArticlesToReadingListDelegate?

    private var theme: Theme
    
    @objc public init(with dataStore: MWKDataStore, articles: [WMFArticle], theme: Theme) {
        self.dataStore = dataStore
        self.articles = articles
        self.theme = theme
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
        readingListsViewController?.createReadingList(with: articles)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar?.topItem?.title = String.localizedStringWithFormat(WMFLocalizedString("add-articles-to-reading-list", value:"Add %1$@ to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add"), "\(String.localizedStringWithFormat(CommonStrings.articleCountFormat, articles.count))")
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
        readingListsViewController.areScrollViewInsetsDeterminedByVisibleHeight = false
        readingListsViewController.delegate = self
        apply(theme: theme)
    }
}

extension AddArticlesToReadingListViewController: ReadingListsViewControllerDelegate {
    func readingListsViewController(_ readingListsViewController: ReadingListsViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
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
}
