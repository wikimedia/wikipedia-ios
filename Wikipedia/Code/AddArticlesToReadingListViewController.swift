import UIKit

class ReadingListsListCollectionViewController: ReadingListsCollectionViewController {
    fileprivate let headerReuseIdentifier = "ReadingListsListCollectionViewControllerHeader"
    fileprivate var headerLayoutEstimate: WMFLayoutEstimate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, addPlaceholder: true)
        collectionView?.allowsSelection = false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //
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
    func didDisappear()
}

class AddArticlesToReadingListViewController: UIViewController {
    
    fileprivate let dataStore: MWKDataStore
    fileprivate let articleURLs: [URL]
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var addButton: UIBarButtonItem?
    @IBOutlet weak var closeButton: UIBarButtonItem?
    
    fileprivate var readingListsListViewController: ReadingListsCollectionViewController?
    @IBOutlet weak var containerView: UIView!
    
    fileprivate var theme: Theme
    
    init(with dataStore: MWKDataStore, articleURLs: [URL], theme: Theme) {
        self.dataStore = dataStore
        self.articleURLs = articleURLs
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
        navigationBar?.topItem?.title = String.localizedStringWithFormat(WMFLocalizedString("add-articles-to-reading-list", value:"Add %1$@ articles to reading list", comment:"Title for the view in charge of adding articles to a reading list - %1$@ is replaced with the number of articles to add"), "\(articleURLs.count)")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        
        readingListsListViewController = ReadingListsListCollectionViewController.init(with: dataStore)
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
        delegate?.didDisappear()
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
