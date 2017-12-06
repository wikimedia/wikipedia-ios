import UIKit

class ReadingListsListCollectionViewController: ReadingListsCollectionViewController {
    fileprivate let headerReuseIdentifier = "ReadingListsListCollectionViewControllerHeader"
    fileprivate var headerLayoutEstimate: WMFLayoutEstimate?
    
    fileprivate let articles: [WMFArticle]
    
    init(with dataStore: MWKDataStore, articles: [WMFArticle]) {
        self.articles = articles
        super.init(with: dataStore)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, addPlaceholder: true)
        collectionView?.allowsMultipleSelection = false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedReadingList = readingList(at: indexPath) else {
            return
        }
        do {
         try readingListsController.add(articles: articles, to: selectedReadingList)
        } catch let err {
            print(err)
            // do something
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            // some confirmation?
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: UICollectionViewDataSource
extension ReadingListsListCollectionViewController {
    func titleForHeaderInSection(_ section: Int) -> String? {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return nil
        }
        let sectionInfo = sections[section]
        guard let readingList = sectionInfo.objects?.first as? ReadingList else {
            return nil
        }
        
        // change
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath)
        guard let headerView = view as? CollectionViewHeader else {
            return view
        }
        headerView.text = titleForHeaderInSection(indexPath.section)
        headerView.apply(theme: theme)
        headerView.layoutMargins = layout.readableMargins
        return headerView
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension ReadingListsListCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        if let estimate = headerLayoutEstimate {
            return estimate
        }
        var estimate = WMFLayoutEstimate(precalculated: false, height: 67)
        guard let placeholder = placeholder(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier) as? CollectionViewHeader else {
            return estimate
        }
        let title = titleForHeaderInSection(section)
        placeholder.prepareForReuse()
        placeholder.text = title
        estimate.height = placeholder.sizeThatFits(CGSize(width: columnWidth, height: UIViewNoIntrinsicMetric)).height
        estimate.precalculated = true
        headerLayoutEstimate = estimate
        return estimate
    }
}

public protocol AddArticlesToReadingListViewControllerDelegate: NSObjectProtocol {
    func viewControllerWillBeDismissed()
}

class AddArticlesToReadingListViewController: UIViewController {
    
    fileprivate let dataStore: MWKDataStore
    fileprivate let articles: [WMFArticle]
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var addButton: UIBarButtonItem?
    @IBOutlet weak var closeButton: UIBarButtonItem?
    
    fileprivate var readingListsListViewController: ReadingListsCollectionViewController?
    @IBOutlet weak var containerView: UIView!
    
    fileprivate var theme: Theme
    
    init(with dataStore: MWKDataStore, articles: [WMFArticle], theme: Theme) {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar?.topItem?.title = String.localizedStringWithFormat(WMFLocalizedString("add-articles-to-reading-list", value:"Add %1$@ articles to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add"), "\(articles.count)")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        
        readingListsListViewController = ReadingListsListCollectionViewController.init(with: dataStore, articles: articles)
        guard let readingListsListViewController = readingListsListViewController else {
            return
        }
        addChildViewController(readingListsListViewController)
        readingListsListViewController.view.frame = containerView.bounds
        readingListsListViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(readingListsListViewController.view)
        readingListsListViewController.didMove(toParentViewController: self)
        apply(theme: theme)
    }
    
    public weak var delegate: AddArticlesToReadingListViewControllerDelegate?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.viewControllerWillBeDismissed()
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
        view.backgroundColor = theme.colors.chromeBackground
        readingListsListViewController?.apply(theme: theme)
    }
}
