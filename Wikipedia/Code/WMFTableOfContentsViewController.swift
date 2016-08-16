
import UIKit

public protocol WMFTableOfContentsViewControllerDelegate : AnyObject {

    /**
     Notifies the delegate that the controller will display
     Use this to update the ToC if needed
     */
    func tableOfContentsControllerWillDisplay(_ controller: WMFTableOfContentsViewController)

    /**
     The delegate is responsible for dismissing the view controller
     */
    func tableOfContentsController(_ controller: WMFTableOfContentsViewController,
                                   didSelectItem item: TableOfContentsItem)

    /**
     The delegate is responsible for dismissing the view controller
     */
    func tableOfContentsControllerDidCancel(_ controller: WMFTableOfContentsViewController)

    func tableOfContentsArticleLanguageURL() -> URL
    
    func tableOfContentsDisplayModeIsModal() -> Bool;
}

open class WMFTableOfContentsViewController: UIViewController,
                                               UITableViewDelegate,
                                               UITableViewDataSource,
                                               WMFTableOfContentsAnimatorDelegate {
    
    let tableOfContentsFunnel: ToCInteractionFunnel

    var tableView: UITableView!

    var items: [TableOfContentsItem] {
        didSet{
            if isViewLoaded {
                let selectedIndexPathBeforeReload = tableView.indexPathForSelectedRow
                tableView.reloadData()
                if let indexPathToReselect = selectedIndexPathBeforeReload , (indexPathToReselect as NSIndexPath).section < tableView.numberOfSections && (indexPathToReselect as NSIndexPath).row < tableView.numberOfRows(inSection: (indexPathToReselect as NSIndexPath).section) {
                    tableView.selectRow(at: indexPathToReselect, animated: false, scrollPosition: .none)
                }
            }
        }
    }
    
    var previousStatusbarStyle: UIStatusBarStyle?

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
        }
        modalPresentationStyle = .custom
        transitioningDelegate = self.animator
                            
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Sections
    func indexPathForItem(_ item: TableOfContentsItem) -> IndexPath? {
        if let row = items.index(where: { item.isEqual($0) }) {
            return IndexPath(row: row, section: 0)
        } else {
            return nil
        }
    }

    open func selectAndScrollToItem(atIndex index: Int, animated: Bool) {
        selectAndScrollToItem(items[index], animated: animated)
    }
    
    open func selectAndScrollToFooterItem(atIndex index: Int, animated: Bool) {
        if let firstFooterIndex = items.index(where: { return $0 as? TableOfContentsFooterItem != nil }) {
            let itemIndex = firstFooterIndex + index
            if itemIndex < items.count {
                selectAndScrollToItem(atIndex: itemIndex, animated: animated)
            }
        }
    }

    open func selectAndScrollToItem(_ item: TableOfContentsItem, animated: Bool) {
        guard let indexPath = indexPathForItem(item) else {
            assertionFailure("No indexPath known for TOC item \(item)")
            return
        }
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            if selectedIndexPath != indexPath {
                deselectAllRows()
            }
        }
        
        var scrollPosition = UITableViewScrollPosition.top
        if let indexPaths = tableView.indexPathsForVisibleRows , indexPaths.contains(indexPath) {
            scrollPosition = .none
        }
        tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
        addHighlightOfItemsRelatedTo(item, animated: false)
    }

    // MARK: - Selection
    func deselectAllRows() {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, element) in visibleIndexPaths.enumerated() {
            if let cell: WMFTableOfContentsCell = tableView.cellForRow(at: element) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(false, animated: false)
            }
        }
    }


    open func addHighlightOfItemsRelatedTo(_ item: TableOfContentsItem, animated: Bool) {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, indexPath) in visibleIndexPaths.enumerated() {
            if let otherItem: TableOfContentsItem = items[(indexPath as NSIndexPath).row],
                   let cell: WMFTableOfContentsCell = tableView.cellForRow(at: indexPath) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(otherItem.shouldBeHighlightedAlongWithItem(item), animated: animated)
            }
        }
    }

    open func addHighlightToItem(_ item: TableOfContentsItem, animated: Bool) {
        if let indexPath = indexPathForItem(item){
            if let cell: WMFTableOfContentsCell = tableView.cellForRow(at: indexPath) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(true, animated: animated)
            }
        }
    }

    fileprivate func didRequestClose(_ controller: WMFTableOfContentsAnimator?) -> Bool {
        tableOfContentsFunnel.logClose()
        delegate?.tableOfContentsControllerDidCancel(self)
        return delegate != nil
    }

    open override func loadView() {
        super.loadView()
        tableView = UITableView(frame: self.view.bounds, style: .grouped)
        
        assert(tableView.style == .grouped, "Use grouped UITableView layout so our WMFTableOfContentsHeader's autolayout works properly. Formerly we used a .Plain table style and set self.tableView.tableHeaderView to our WMFTableOfContentsHeader, but doing so caused autolayout issues for unknown reasons. Instead, we now use a grouped layout and use WMFTableOfContentsHeader with viewForHeaderInSection, which plays nicely with autolayout. (grouped layouts also used because they allow the header to scroll *with* the section cells rather than floating)")
        
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.mas_makeConstraints { make in
            make?.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
        tableView.backgroundView = nil
    }

    // MARK: - UIViewController
    open override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(WMFTableOfContentsCell.wmf_classNib(),
                              forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier())
        tableView.estimatedRowHeight = 41
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 32
        
        if let delegate = delegate , delegate.tableOfContentsDisplayModeIsModal() {
            tableView.backgroundColor = UIColor.wmf_modalTableOfContentsBackground()
        } else {
            tableView.backgroundColor = UIColor.wmf_inlineTableOfContentsBackground()
        }
        automaticallyAdjustsScrollViewInsets = false
        tableView.contentInset = UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.size.height, 0, 0, 0)
        tableView.separatorStyle = .none
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.tableOfContentsControllerWillDisplay(self)
        tableOfContentsFunnel.logOpen()
        previousStatusbarStyle = UIApplication.shared.statusBarStyle
        UIApplication.shared.setStatusBarStyle(.default, animated: animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deselectAllRows()
        if let previousStatusbarStyle = previousStatusbarStyle {
            UIApplication.shared.setStatusBarStyle(previousStatusbarStyle, animated: animated)
        }
    }
    
    // MARK: - UITableViewDataSource
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WMFTableOfContentsCell.reuseIdentifier(), for: indexPath) as! WMFTableOfContentsCell
        let selectedItems: [TableOfContentsItem] = tableView.indexPathsForSelectedRows?.map() { items[($0 as NSIndexPath).row] } ?? []
        let item = items[(indexPath as NSIndexPath).row]
        let shouldHighlight = selectedItems.reduce(false) { shouldHighlight, selectedItem in
            shouldHighlight || item.shouldBeHighlightedAlongWithItem(selectedItem)
        }
        cell.backgroundColor = tableView.backgroundColor
        cell.contentView.backgroundColor = tableView.backgroundColor
        
        cell.titleIndentationLevel = item.indentationLevel
        cell.titleLabel.text = item.titleText
        cell.titleLabel.font = item.itemType.titleFont
        cell.titleColor = item.itemType.titleColor
        
        cell.setNeedsLayout()

        cell.setSectionSelected(shouldHighlight, animated: false)
        return cell
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let delegate = delegate {
            let header = WMFTableOfContentsHeader.wmf_viewFromClassNib()
            header?.articleURL = delegate.tableOfContentsArticleLanguageURL()
            header?.backgroundColor = tableView.backgroundColor
            return header
        } else {
            return nil
        }
    }

    // MARK: - UITableViewDelegate

    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let item = items[(indexPath as NSIndexPath).row]
        addHighlightToItem(item, animated: true)
        return true
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[(indexPath as NSIndexPath).row]
        tableOfContentsFunnel.logClick()
        addHighlightOfItemsRelatedTo(item, animated: true)
        delegate?.tableOfContentsController(self, didSelectItem: item)
    }

    open func tableOfContentsAnimatorDidTapBackground(_ controller: WMFTableOfContentsAnimator) {
        didRequestClose(controller)
    }

    // MARK: - UIScrollViewDelegate
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let item = items[(indexPath as NSIndexPath).row]
            addHighlightOfItemsRelatedTo(item, animated: true)
        }
    }

    // MARK: - UIAccessibilityAction
    open override func accessibilityPerformEscape() -> Bool {
        return didRequestClose(nil)
    }
    
    // MARK: - UIAccessibilityAction
    open override func accessibilityPerformMagicTap() -> Bool {
        return didRequestClose(nil)
    }

}

