
import UIKit

protocol TalkPageTopicListDelegate: class {
    func tappedTopic(_ topic: TalkPageTopic, viewController: TalkPageTopicListViewController)
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageTopicListViewController)
    func didBecomeActiveAfterCompletingActivity(ofType completedActivityType: UIActivity.ActivityType?)
}

class TalkPageTopicListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageTopicListDelegate?
    
    private let dataStore: MWKDataStore
    private let talkPageTitle: String
    private let talkPage: TalkPage
    private let fetchedResultsController: NSFetchedResultsController<TalkPageTopic>
    
    private let reuseIdentifier = "TalkPageTopicCell"
    
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageTopic>!
    private var cellLayoutEstimate: ColumnarCollectionViewLayoutHeightEstimate?
    private var toolbar: UIToolbar?
    private var shareIcon: IconBarButtonItem?
    private let siteURL: URL
    private let type: TalkPageType
    private let talkPageSemanticContentAttribute: UISemanticContentAttribute

    private var completedActivityType: UIActivity.ActivityType?

    required init(dataStore: MWKDataStore, talkPageTitle: String, talkPage: TalkPage, siteURL: URL, type: TalkPageType, talkPageSemanticContentAttribute: UISemanticContentAttribute) {
        self.dataStore = dataStore
        self.talkPageTitle = talkPageTitle
        self.talkPage = talkPage
        self.siteURL = siteURL
        self.type = type
        self.talkPageSemanticContentAttribute = talkPageSemanticContentAttribute
        
        let request: NSFetchRequest<TalkPageTopic> = TalkPageTopic.fetchRequest()
        request.predicate = NSPredicate(format: "talkPage == %@ && isIntro == NO",  talkPage)
        request.relationshipKeyPathsForPrefetching = ["content"]
        request.sortDescriptors = [NSSortDescriptor(key: "sort", ascending: true)]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        setupCollectionViewUpdater()
        setupToolbar()

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didBecomeActive() {
        delegate?.didBecomeActiveAfterCompletingActivity(ofType: completedActivityType)
        completedActivityType = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cellLayoutEstimate = nil
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            //
        }) { _ in
            self.updateScrollViewInsets()
        }
        super.willTransition(to: newCollection, with: coordinator)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.scrollViewDidScroll(scrollView, viewController: self)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let sectionsCount = fetchedResultsController.sections?.count else {
            return 0
        }
        return sectionsCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections,
            section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TalkPageTopicCell else {
                return UICollectionViewCell()
        }
        
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        // The layout estimate can be re-used in this case because label is one line, meaning the cell
        // size only varies with font size. The layout estimate is nil'd when the font size changes on trait collection change
        if let estimate = cellLayoutEstimate {
            return estimate
        }
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? TalkPageTopicCell else {
            return estimate
        }
        configure(cell: placeholderCell, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        cellLayoutEstimate = estimate
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topic = fetchedResultsController.object(at: indexPath)
        delegate?.tappedTopic(topic, viewController: self)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.backgroundColor = theme.colors.baseBackground
        toolbar?.barTintColor = theme.colors.chromeBackground
        shareIcon?.apply(theme: theme)
    }
}

//MARK: Private

private extension TalkPageTopicListViewController {
    
    func registerCells() {
        layoutManager.register(TalkPageTopicCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
    }
    
    func setupCollectionViewUpdater() {
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
    }
    
    func setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.barTintColor = theme.colors.chromeBackground
        
        let toolbarHeight = CGFloat(44)
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: toolbarHeight, right: 0)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        let guide = view.safeAreaLayoutGuide
        let heightConstraint = toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight)
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor)
        let trailingConstraint = view.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor)
        let bottomConstraint = guide.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        
        NSLayoutConstraint.activate([heightConstraint, leadingConstraint, trailingConstraint, bottomConstraint])
        
        let shareIcon = IconBarButtonItem(iconName: "share", target: self, action: #selector(tappedShare(_:)), for: .touchUpInside)
        shareIcon.apply(theme: theme)
        shareIcon.accessibilityLabel = CommonStrings.accessibilityShareTitle
        
        let spacer1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let spacer2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [spacer1, shareIcon, spacer2]

        self.toolbar = toolbar
        self.shareIcon = shareIcon
    }
    
    @objc func tappedShare(_ sender: UIButton) {
        var talkPageURLComponents = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
        talkPageURLComponents?.path = "/wiki/\(talkPageTitle)"
        guard let talkPageURL = talkPageURLComponents?.url else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [talkPageURL], applicationActivities: [TUSafariActivity()])
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, _: [Any]?, _: Error?) in
            if completed {
                self.completedActivityType = activityType
            }
        }
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .down
        }
        
        present(activityViewController, animated: true)
    }
    
    func configure(cell: TalkPageTopicCell, at indexPath: IndexPath) {
        let topic = fetchedResultsController.object(at: indexPath)
        guard let title = topic.title else {
            return
        }
        
        cell.configure(title: title, isRead: topic.isRead)
        cell.layoutMargins = layout.itemLayoutMargins
        cell.semanticContentAttributeOverride = talkPageSemanticContentAttribute
        cell.apply(theme: theme)
    }
}

//MARK: CollectionViewUpdaterDelegate

extension TalkPageTopicListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageTopicCell else {
                continue
            }
            
            configure(cell: cell, at: indexPath)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}
