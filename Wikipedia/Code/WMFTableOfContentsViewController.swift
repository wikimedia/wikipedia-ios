
import UIKit
import Masonry

public protocol WMFTableOfContentsViewControllerDelegate : AnyObject {

    /**
     Notifies the delegate that the controller will display
     Use this to update the ToC if needed
     */
    func tableOfContentsControllerWillDisplay(controller: WMFTableOfContentsViewController)

    /**
     The delegate is responsible for dismissing the view controller
     */
    func tableOfContentsController(controller: WMFTableOfContentsViewController,
                                   didSelectItem item: TableOfContentsItem)

    /**
     The delegate is responsible for dismissing the view controller
     */
    func tableOfContentsControllerDidCancel(controller: WMFTableOfContentsViewController)

    func tableOfContentsArticleSite() -> MWKSite
}

public class WMFTableOfContentsViewController: UIViewController,
                                               UITableViewDelegate,
                                               UITableViewDataSource,
                                               WMFTableOfContentsAnimatorDelegate {
    
    let tableOfContentsFunnel: ToCInteractionFunnel

    var tableView: UITableView!

    var items: [TableOfContentsItem] {
        didSet{
            if isViewLoaded() {
                tableView.reloadData()
            }
        }
    }

    //optional becuase it requires a reference to self to inititialize
    var animator: WMFTableOfContentsAnimator?

    weak var delegate: WMFTableOfContentsViewControllerDelegate?

    // MARK: - Init
    public required init(presentingViewController: UIViewController,
                         items: [TableOfContentsItem],
                         delegate: WMFTableOfContentsViewControllerDelegate) {
        self.items = items
        self.delegate = delegate
        tableOfContentsFunnel = ToCInteractionFunnel()
        super.init(nibName: nil, bundle: nil)
        animator = WMFTableOfContentsAnimator(presentingViewController: presentingViewController, presentedViewController: self)
        animator?.delegate = self
        modalPresentationStyle = .Custom
        transitioningDelegate = self.animator
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

    public func selectAndScrollToItem(atIndex index: Int, animated: Bool) {
        selectAndScrollToItem(items[index], animated: animated)
    }

    public func selectAndScrollToItem(item: TableOfContentsItem, animated: Bool) {
        guard let indexPath = indexPathForItem(item) else {
            fatalError("No indexPath known for TOC item \(item)")
        }
        deselectAllRows()
        tableView.selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition.Top)
        addHighlightOfItemsRelatedTo(item, animated: false)
    }

    // MARK: - Selection
    func deselectAllRows() {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, element) in visibleIndexPaths.enumerate() {
            if let cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(element) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(false, animated: false)
            }
        }
    }
    func deselectAllRowsExceptForIndexPath(indexpath: NSIndexPath?, animated: Bool) {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, element) in visibleIndexPaths.enumerate() {
            
            if let cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(element) as? WMFTableOfContentsCell  {
                if let indexpath = indexpath{
                    if element.isEqual(indexpath){
                        cell.setSectionSelected(true, animated: false)
                        continue
                    }
                }
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

    public func addHighlightToItem(item: TableOfContentsItem, animated: Bool) {
        if let indexPath = indexPathForItem(item){
            if let cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(indexPath) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(true, animated: animated)
            }
        }
    }

    public override func loadView() {
        super.loadView()
        tableView = UITableView(frame: self.view.bounds, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.whiteColor()
    }

    // MARK: - UIViewController
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(WMFTableOfContentsCell.wmf_classNib(),
                              forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier())
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 25
        automaticallyAdjustsScrollViewInsets = false
        tableView.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.size.height, 0, 0, 0)
        tableView.separatorStyle = .None
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.tableOfContentsControllerWillDisplay(self)
        tableOfContentsFunnel.logOpen()
    }

    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        deselectAllRows()
    }
    
    // MARK: - UITableViewDataSource
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = WMFTableOfContentsHeader.wmf_viewFromClassNib()
        assert(delegate != nil, "TOC delegate not set!")
        header.articleSite = delegate?.tableOfContentsArticleSite()
        return header
    }
    
    public func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let item = items[indexPath.row]
        addHighlightToItem(item, animated: true)
        return true
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        deselectAllRowsExceptForIndexPath(indexPath, animated: false)
        tableOfContentsFunnel.logClick()
        addHighlightOfItemsRelatedTo(item, animated: true)
        delegate?.tableOfContentsController(self, didSelectItem: item)
    }

    public func tableOfContentsAnimatorDidTapBackground(controller: WMFTableOfContentsAnimator) {
        tableOfContentsFunnel.logClose()
        delegate?.tableOfContentsControllerDidCancel(self)
    }

    // MARK: - UIScrollViewDelegate
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let item = items[indexPath.row]
            addHighlightOfItemsRelatedTo(item, animated: true)
        }
    }

}

