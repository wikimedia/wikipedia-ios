import UIKit
import Masonry
import WMFUI

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

    func tableOfContentsArticleLanguageURL() -> NSURL?
    
    func tableOfContentsDisplayModeIsModal() -> Bool;
}

public class WMFTableOfContentsViewController: UIViewController,
                                               UITableViewDelegate,
                                               UITableViewDataSource,
                                               WMFTableOfContentsAnimatorDelegate {
    
    let tableOfContentsFunnel: ToCInteractionFunnel
    
    var displaySide = WMFTableOfContentsDisplaySideLeft {
        didSet {
            animator?.displaySide = displaySide
        }
    }
    
    var displayMode = WMFTableOfContentsDisplayModeModal {
        didSet {
            animator?.displayMode = displayMode
        }
    }

    lazy var tableView: UITableView = {
        
        let tv = UITableView(frame: CGRectZero, style: .Grouped)
        
        assert(tv.style == .Grouped, "Use grouped UITableView layout so our WMFTableOfContentsHeader's autolayout works properly. Formerly we used a .Plain table style and set self.tableView.tableHeaderView to our WMFTableOfContentsHeader, but doing so caused autolayout issues for unknown reasons. Instead, we now use a grouped layout and use WMFTableOfContentsHeader with viewForHeaderInSection, which plays nicely with autolayout. (grouped layouts also used because they allow the header to scroll *with* the section cells rather than floating)")
        
        tv.separatorStyle = .None
        tv.delegate = self
        tv.dataSource = self
        tv.backgroundView = nil

        tv.registerNib(WMFTableOfContentsCell.wmf_classNib(),
                              forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier())
        tv.estimatedRowHeight = 41
        tv.rowHeight = UITableViewAutomaticDimension
        
        tv.sectionHeaderHeight = UITableViewAutomaticDimension
        tv.estimatedSectionHeaderHeight = 32
        
        tv.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.size.height, 0, 0, 0)
        tv.separatorStyle = .None
        

        //add to the view now to ensure view did load is kicked off
        self.view.addSubview(tv)

        return tv
    }()

    var items: [TableOfContentsItem] {
        didSet{
            if isViewLoaded() {
                tableView.semanticContentAttribute = view.semanticContentAttribute
                let selectedIndexPathBeforeReload = tableView.indexPathForSelectedRow
                tableView.reloadData()
                if let indexPathToReselect = selectedIndexPathBeforeReload where indexPathToReselect.section < tableView.numberOfSections && indexPathToReselect.row < tableView.numberOfRowsInSection(indexPathToReselect.section) {
                    tableView.selectRowAtIndexPath(indexPathToReselect, animated: false, scrollPosition: .None)
                }
            }
        }
    }
    
    //optional because it requires a reference to self to inititialize
    var animator: WMFTableOfContentsAnimator?

    weak var delegate: WMFTableOfContentsViewControllerDelegate?

    // MARK: - Init
    public required init(presentingViewController: UIViewController?,
                         items: [TableOfContentsItem],
                         delegate: WMFTableOfContentsViewControllerDelegate) {
        self.items = items
        self.delegate = delegate
        tableOfContentsFunnel = ToCInteractionFunnel()
        super.init(nibName: nil, bundle: nil)
        if let presentingViewController = presentingViewController {
            animator = WMFTableOfContentsAnimator(presentingViewController: presentingViewController, presentedViewController: self)
            animator?.delegate = self
            animator?.displaySide = displaySide
            animator?.displayMode = displayMode
        }
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
        guard index < items.count else {
            assertionFailure("Trying to select/scroll to an item put of range")
            return
        }
        selectAndScrollToItem(items[index], animated: animated)
    }
    
    
    public func selectAndScrollToFooterItem(atIndex index: Int, animated: Bool) {
        if let firstFooterIndex = items.indexOf({ return $0 as? TableOfContentsFooterItem != nil }) {
            let itemIndex = firstFooterIndex + index
            if itemIndex < items.count {
                selectAndScrollToItem(atIndex: itemIndex, animated: animated)
            }
        }
    }

    public func selectAndScrollToItem(item: TableOfContentsItem?, animated: Bool) {
        guard let item = item else{
            assertionFailure("Passing nil TOC item")
            return
        }
        guard let indexPath = indexPathForItem(item) else {
            assertionFailure("No indexPath known for TOC item \(item)")
            return
        }
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            if !selectedIndexPath.isEqual(indexPath) {
                deselectAllRows()
            }
        }
        
        var scrollPosition = UITableViewScrollPosition.Top
        if let indexPaths = tableView.indexPathsForVisibleRows where indexPaths.contains(indexPath) {
            scrollPosition = .None
        }
        tableView.selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: scrollPosition)
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

    private func didRequestClose(controller: WMFTableOfContentsAnimator?) -> Bool {
        tableOfContentsFunnel.logClose()
        delegate?.tableOfContentsControllerDidCancel(self)
        return delegate != nil
    }

    // MARK: - UIViewController
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
        
        if let delegate = delegate where delegate.tableOfContentsDisplayModeIsModal() {
            tableView.backgroundColor = UIColor.wmf_modalTableOfContentsBackgroundColor()
        } else {
            tableView.backgroundColor = UIColor.wmf_inlineTableOfContentsBackgroundColor()
        }

        automaticallyAdjustsScrollViewInsets = false
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
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    // MARK: - UITableViewDataSource
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(WMFTableOfContentsCell.reuseIdentifier(), forIndexPath: indexPath) as! WMFTableOfContentsCell
        let selectedItems: [TableOfContentsItem] = tableView.indexPathsForSelectedRows?.map() { items[$0.row] } ?? []
        let item = items[indexPath.row]
        let shouldHighlight = selectedItems.reduce(false) { shouldHighlight, selectedItem in
            shouldHighlight || item.shouldBeHighlightedAlongWithItem(selectedItem)
        }
        cell.backgroundColor = tableView.backgroundColor
        cell.contentView.backgroundColor = tableView.backgroundColor
        
        cell.semanticContentAttribute = view.semanticContentAttribute
        cell.wmf_applySemanticContentAttributeToAllSubviewsRecursively()
        
        cell.titleIndentationLevel = item.indentationLevel
        cell.titleLabel.text = item.titleText
        cell.titleLabel.font = UIFont.wmf_preferredFontForFontFamily(item.itemType.titleFontFamily, withTextStyle: item.itemType.titleFontTextStyle, compatibleWithTraitCollection: self.traitCollection)
        cell.titleColor = item.itemType.titleColor

        cell.setNeedsLayout()

        cell.setSectionSelected(shouldHighlight, animated: false)
        return cell
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let delegate = delegate {
            let header = WMFTableOfContentsHeader.wmf_viewFromClassNib()
            header.articleURL = delegate.tableOfContentsArticleLanguageURL()
            header.backgroundColor = tableView.backgroundColor
            header.semanticContentAttribute = view.semanticContentAttribute
            header.wmf_applySemanticContentAttributeToAllSubviewsRecursively()
            return header
        } else {
            return nil
        }
    }

    // MARK: - UITableViewDelegate

    public func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let item = items[indexPath.row]
        addHighlightToItem(item, animated: true)
        return true
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        tableOfContentsFunnel.logClick()
        addHighlightOfItemsRelatedTo(item, animated: true)
        delegate?.tableOfContentsController(self, didSelectItem: item)
    }

    public func tableOfContentsAnimatorDidTapBackground(controller: WMFTableOfContentsAnimator) {
        didRequestClose(controller)
    }

    // MARK: - UIScrollViewDelegate
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let item = items[indexPath.row]
            addHighlightOfItemsRelatedTo(item, animated: true)
        }
    }

    // MARK: - UIAccessibilityAction
    public override func accessibilityPerformEscape() -> Bool {
        return didRequestClose(nil)
    }
    
    // MARK: - UIAccessibilityAction
    public override func accessibilityPerformMagicTap() -> Bool {
        return didRequestClose(nil)
    }

}

