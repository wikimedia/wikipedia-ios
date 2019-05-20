
import UIKit

protocol TalkPageReplyListViewControllerDelegate: class {
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController)
    func tappedPublish(topic: TalkPageTopic, composeText: String, viewController: TalkPageReplyListViewController)
}

class TalkPageReplyListViewController: ColumnarCollectionViewController {
    
    weak var delegate: TalkPageReplyListViewControllerDelegate?
    
    private let topic: TalkPageTopic
    private let dataStore: MWKDataStore
    private var fetchedResultsController: NSFetchedResultsController<TalkPageReply>
    
    private let reuseIdentifier = "TalkPageReplyCell"
    
    private var collectionViewUpdater: CollectionViewUpdater<TalkPageReply>!
    
    private lazy var publishButton: UIBarButtonItem = UIBarButtonItem(title: CommonStrings.publishTitle, style: .done, target: self, action: #selector(tappedPublish(_:)))
    
    private var composeText: String?
    private var footerView: TalkPageReplyFooterView?
    private var originalFooterViewFrame: CGRect?
    
    private var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    
    private var showingCompose = false {
        didSet {
            if showingCompose != oldValue {
                //todo: better reload
                collectionView.reloadData()
                collectionView.layoutIfNeeded()
            }
            
            if showingCompose {
                publishButton.isEnabled = false
                navigationItem.rightBarButtonItem = publishButton
                navigationBar.updateNavigationItems()
            } else {
                navigationItem.rightBarButtonItem = nil
                navigationBar.updateNavigationItems()
            }
        }
    }
    
    var isShowingKeyboard: Bool {
        return keyboardFrame != nil
    }
    
    required init(dataStore: MWKDataStore, topic: TalkPageTopic) {
        self.dataStore = dataStore
        self.topic = topic
        
        let request: NSFetchRequest<TalkPageReply> = TalkPageReply.fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@",  topic)
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
        setupBackgroundTap()
        
        collectionView.keyboardDismissMode = .onDrag
        navigationBar.isBarHidingEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func keyboardWillChangeFrame(_ notification: Notification) {
        
        super.keyboardWillChangeFrame(notification)
        
        if let footerView = footerView,
            let keyboardFrame = keyboardFrame {
            
            if keyboardFrame.height == 0 {
                return
            }
            
            scrollToBottom()
            
            let convertedComposeViewFrame = footerView.composeView.convert(footerView.composeTextView.frame, to: view)

            //shift keyboard frame if necessary so compose view is in visible window
            let navBarHeight = navigationBar.visibleHeight
            let newHeight = keyboardFrame.minY - navBarHeight
            
            let newRect = CGRect(x: convertedComposeViewFrame.minX, y: navBarHeight, width: convertedComposeViewFrame.width, height: newHeight)
            let newConvertedRect = footerView.composeView.convert(newRect, from: view)
        
            let keyboardAnimationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.2
            let duration = keyboardAnimationDuration == 0 ? 0.2 : keyboardAnimationDuration
            
            footerView.dividerView.isHidden = true
            
            UIView.animate(withDuration: duration, animations: {
                footerView.composeTextView.frame = newConvertedRect
            })
        }
    }
    
    override func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        //no-op, avoiding updateScrollViewInsets() call in superclass
    }
    
    override func keyboardWillHide(_ notification: Notification) {
        super.keyboardWillHide(notification)
        
        footerView?.dividerView.isHidden = false
        
        let keyboardAnimationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.2
        let duration = keyboardAnimationDuration == 0 ? 0.2 : keyboardAnimationDuration
        
        UIView.animate(withDuration: duration, animations: {
            self.footerView?.resetComposeTextViewFrame()
        })
    }
    
    @objc func tappedPublish(_ sender: UIBarButtonItem) {
        
        guard let composeText = composeText,
            composeText.count > 0 else {
                assertionFailure("User should be able to tap Publish if they have not written a reply.")
                return
        }
        delegate?.tappedPublish(topic: topic, composeText: composeText, viewController: self)
        showingCompose = false
        footerView?.resetCompose()
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
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TalkPageReplyCell else {
                return UICollectionViewCell()
        }
        
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: reuseIdentifier) as? TalkPageReplyCell else {
            return estimate
        }
        configure(cell: placeholderCell, at: indexPath)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TalkPageHeaderView.identifier, for: indexPath) as? TalkPageHeaderView {
                configure(header: header)
                return header
        }
        
        if kind == UICollectionView.elementKindSectionFooter,
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TalkPageReplyFooterView.identifier, for: indexPath) as? TalkPageReplyFooterView {
            self.footerView = footer
            configure(footer: footer)
            return footer
        }
        
        return UICollectionReusableView()
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let header = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.identifier) as? TalkPageHeaderView else {
            return estimate
        }
        
        configure(header: header)
        estimate.height = header.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = false
        return estimate
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 100)
        guard let footer = layoutManager.placeholder(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TalkPageReplyFooterView.identifier) as? TalkPageReplyFooterView else {
            return estimate
        }
        configure(footer: footer)
        estimate.height = footer.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}

//MARK: CollectionViewUpdaterDelegate

extension TalkPageReplyListViewController: CollectionViewUpdaterDelegate {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) where T : NSFetchRequestResult {
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageTopicCell,
                let title = fetchedResultsController.object(at: indexPath).text else {
                    continue
            }
            
            cell.configure(title: title)
        }
    }
    
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView) where T : NSFetchRequestResult {
        //no-op
    }
}

//MARK: Private

private extension TalkPageReplyListViewController {
    
    func registerCells() {
        layoutManager.register(TalkPageReplyCell.self, forCellWithReuseIdentifier: reuseIdentifier, addPlaceholder: true)
        layoutManager.register(TalkPageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.identifier, addPlaceholder: true)
        layoutManager.register(TalkPageReplyFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TalkPageReplyFooterView.identifier, addPlaceholder: true)
    }
    
    func setupCollectionViewUpdater() {
        collectionViewUpdater = CollectionViewUpdater(fetchedResultsController: fetchedResultsController, collectionView: collectionView)
        collectionViewUpdater?.delegate = self
        collectionViewUpdater?.performFetch()
    }
    
    func setupBackgroundTap() {
        backgroundTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedBackground(_:)))
        view.addGestureRecognizer(backgroundTapGestureRecognizer)
    }
    
    @objc func tappedBackground(_ tapGestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func configure(header: TalkPageHeaderView) {
        
        guard let title = topic.title else {
                return
        }
        
        let headerText = WMFLocalizedString("talk-page-topic-title", value: "Discussion", comment: "This header label is displayed at the top of a talk page topic thread.").localizedUppercase
        
        let viewModel = TalkPageHeaderView.ViewModel(header: headerText, title: title, info: nil)
        
        header.configure(viewModel: viewModel)
        header.layoutMargins = layout.itemLayoutMargins
        header.apply(theme: theme)
    }
    
    func configure(footer: TalkPageReplyFooterView) {
        footer.delegate = self
        footer.showingCompose = showingCompose
        footer.layoutMargins = layout.itemLayoutMargins
        footer.layer.zPosition = 999
        footer.apply(theme: theme)
    }
    
    func configure(cell: TalkPageReplyCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        guard let title = item.text,
        item.depth >= 0 else {
            assertionFailure("Invalid depth")
            return
        }
        
        cell.delegate = self
        cell.configure(title: title, depth: UInt(item.depth))
        cell.layoutMargins = layout.itemLayoutMargins
        cell.apply(theme: theme)
    }
    
    func scrollToBottom() {
        let bottomOffset = CGPoint(x: 0, y: (collectionView.contentSize.height - collectionView.frame.size.height) + collectionView.adjustedContentInset.bottom)
        scrollView?.setContentOffset(bottomOffset, animated: true)
    }
}

extension TalkPageReplyListViewController: TalkPageReplyCellDelegate {
    func tappedLink(_ url: URL, cell: TalkPageReplyCell) {
        
        delegate?.tappedLink(url, viewController: self)
    }
}

extension TalkPageReplyListViewController: ReplyButtonFooterViewDelegate {
    func composeTextDidChange(text: String?) {
        publishButton.isEnabled = text?.count ?? 0 > 0
        composeText = text
    }
    
    func tappedReply(from view: TalkPageReplyFooterView) {

        showingCompose = !showingCompose
        scrollToBottom()
        originalFooterViewFrame = footerView?.frame
    }
    
    var collectionViewFrame: CGRect {
        return collectionView.frame
    }
}
