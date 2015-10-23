
import UIKit

public protocol WMFTableOfContentsViewControllerDelegate : AnyObject {

    func tableOfContentsController(controller: WMFTableOfContentsViewController,
                                   didSelectItem item: TableOfContentsItem)

    func tableOfContentsControllerDidCancel(controller: WMFTableOfContentsViewController)
}

public class WMFTableOfContentsViewController: UITableViewController,
                                               UIViewControllerTransitioningDelegate,
                                               WMFTableOfContentsPresentationControllerTapDelegate  {
    let tableOfContentsFunnel: ToCInteractionFunnel

    weak var delegate: WMFTableOfContentsViewControllerDelegate?

    let items: [TableOfContentsItem]

    // MARK: - Init
    public required init(sectionList: MWKSectionList, delegate: WMFTableOfContentsViewControllerDelegate) {
        items = {
            // HAX: need to forcibly downcast each section object to our protocol type. yay objc/swift interop!
            var xs = sectionList.entries.map() { $0 as! TableOfContentsItem }
            xs.append(TableOfContentsReadMoreItem())
            return xs
        }()
        self.delegate = delegate
        tableOfContentsFunnel = ToCInteractionFunnel()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Sections

    func indexPathForItem(item: TableOfContentsItem) -> NSIndexPath? {
        if let row = items.indexOf({ item.isEqual($0) }) {
            return NSIndexPath(forRow: row, inSection: 0)
        } else {
            return nil
        }
    }

    public func scrollToItem(item: TableOfContentsItem, animated: Bool) {
        tableView.scrollToRowAtIndexPath(indexPathForItem(item)!,
                                         atScrollPosition: UITableViewScrollPosition.Top,
                                         animated: animated)
    }

    public func selectAndScrollToItem(item: TableOfContentsItem, animated: Bool) {
        if let indexPath = indexPathForItem(item) {
            deselectAllRows()
            tableView.selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition.Top)
            addHighlightOfItemsRelatedTo(item, animated: false)
        }
    }
    
    // MARK: - Selection

    public func deselectAllRows() {
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        for (_, element) in selectedIndexPaths.enumerate() {
            if let cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(element) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(false, animated: false)
            }
        }
    }
    
    public func addHighlightOfItemsRelatedTo(item: TableOfContentsItem, animated: Bool) {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, indexPath) in visibleIndexPaths.enumerate() {
            if let otherItem: TableOfContentsItem = items[indexPath.row],
                   cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(indexPath) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(otherItem.shouldBeHighlightedAlongWithItem(item), animated: animated)
            }
        }
    }
    
    // MARK: - UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(WMFTableOfContentsCell.wmf_classNib(),
                              forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier());
        clearsSelectionOnViewWillAppear = false
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        automaticallyAdjustsScrollViewInsets = false
        tableView.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.size.height, 0, 0, 0)
        tableView.separatorStyle = .None
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableOfContentsFunnel.logOpen()
    }

    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        deselectAllRows()
    }
    
    // MARK: - UITableViewDataSource
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(WMFTableOfContentsCell.reuseIdentifier(), forIndexPath: indexPath) as! WMFTableOfContentsCell
        let selectedItems: [TableOfContentsItem] = tableView.indexPathsForSelectedRows?.map() { items[$0.row] } ?? []
        let item = items[indexPath.row]
        let shouldHighlight = selectedItems.reduce(false) { shouldHighlight, selectedItem in
            shouldHighlight || item.shouldBeHighlightedAlongWithItem(selectedItem)
        }
        cell.setItem(item)
        cell.setSectionSelected(shouldHighlight, animated: false)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        deselectAllRows()
        tableOfContentsFunnel.logClick()
        addHighlightOfItemsRelatedTo(item, animated: true)
        delegate?.tableOfContentsController(self, didSelectItem: item)
    }

    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        if presented == self {
            return WMFTableOfContentsPresentationController(presentedViewController: presented, presentingViewController: presenting, tapDelegate: self)
        }
        
        return nil
    }
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if presented == self {
            return WMFTableOfContentsAnimator(isPresenting: true)
        }
        else {
            return nil
        }
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if dismissed == self {
            return WMFTableOfContentsAnimator(isPresenting: false)
        }
        else {
            return nil
        }
    }
    
    // MARK: - WMFTableOfContentsPresentationControllerTapDelegate

    public func tableOfContentsPresentationControllerDidTapBackground(controller: WMFTableOfContentsPresentationController) {
        tableOfContentsFunnel.logClose()
        delegate?.tableOfContentsControllerDidCancel(self)
    }
}
