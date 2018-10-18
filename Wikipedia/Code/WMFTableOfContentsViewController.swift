import UIKit
import WMF

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

    func tableOfContentsArticleLanguageURL() -> URL?
    
    func tableOfContentsDisplayModeIsModal() -> Bool;
}

open class WMFTableOfContentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, WMFTableOfContentsAnimatorDelegate, Themeable {
    
    fileprivate var theme = Theme.standard
    
    let tableOfContentsFunnel: ToCInteractionFunnel

    let semanticContentAttributeOverride: UISemanticContentAttribute
    
    @objc var displaySide = WMFTableOfContentsDisplaySide.left {
        didSet {
            animator?.displaySide = displaySide
        }
    }
    
    @objc var displayMode = WMFTableOfContentsDisplayMode.modal {
        didSet {
            animator?.displayMode = displayMode
        }
    }

    @objc let tableView: UITableView = UITableView(frame: .zero, style: .grouped)

    var items: [TableOfContentsItem] {
        didSet{
            if isViewLoaded {
                let selectedIndexPathBeforeReload = tableView.indexPathForSelectedRow
                tableView.reloadData()
                if let indexPathToReselect = selectedIndexPathBeforeReload, indexPathToReselect.section < tableView.numberOfSections && indexPathToReselect.row < tableView.numberOfRows(inSection: indexPathToReselect.section) {
                    tableView.selectRow(at: indexPathToReselect, animated: false, scrollPosition: .none)
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
                         delegate: WMFTableOfContentsViewControllerDelegate,
                         semanticContentAttribute: UISemanticContentAttribute,
                         theme: Theme) {
        self.theme = theme
        self.semanticContentAttributeOverride = semanticContentAttribute
        self.items = items
        self.delegate = delegate
        tableOfContentsFunnel = ToCInteractionFunnel()
        super.init(nibName: nil, bundle: nil)
        if let presentingViewController = presentingViewController {
            animator = WMFTableOfContentsAnimator(presentingViewController: presentingViewController, presentedViewController: self)
            animator?.apply(theme: theme)
            animator?.delegate = self
            animator?.displaySide = displaySide
            animator?.displayMode = displayMode
        }
        modalPresentationStyle = .custom
        transitioningDelegate = self.animator
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
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

    @objc open func selectAndScrollToItem(atIndex index: Int, animated: Bool) {
        guard index < items.count else {
            assertionFailure("Trying to select/scroll to an item put of range")
            return
        }
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

    open func selectAndScrollToItem(_ item: TableOfContentsItem?, animated: Bool) {
        guard let item = item else{
            assertionFailure("Passing nil TOC item")
            return
        }
        guard let indexPath = indexPathForItem(item) else {
            assertionFailure("No indexPath known for TOC item \(item)")
            return
        }

        guard indexPath.section < tableView.numberOfSections && indexPath.row < tableView.numberOfRows(inSection: indexPath.section) else {
            assertionFailure("Attempted to select out of range item \(item)")
            return
        }
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            if selectedIndexPath != indexPath {
                deselectAllRows()
            }
        }
        
        var scrollPosition = UITableView.ScrollPosition.top
        if let indexPaths = tableView.indexPathsForVisibleRows, indexPaths.contains(indexPath) {
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
            let otherItem: TableOfContentsItem = items[indexPath.row]
            if let cell: WMFTableOfContentsCell = tableView.cellForRow(at: indexPath) as? WMFTableOfContentsCell  {
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

    // MARK: - UIViewController
    open override func viewDidLoad() {
        super.viewDidLoad()

        assert(tableView.style == .grouped, "Use grouped UITableView layout so our WMFTableOfContentsHeader's autolayout works properly. Formerly we used a .Plain table style and set self.tableView.tableHeaderView to our WMFTableOfContentsHeader, but doing so caused autolayout issues for unknown reasons. Instead, we now use a grouped layout and use WMFTableOfContentsHeader with viewForHeaderInSection, which plays nicely with autolayout. (grouped layouts also used because they allow the header to scroll *with* the section cells rather than floating)")

        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = nil

        tableView.register(WMFTableOfContentsCell.wmf_classNib(),
                    forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier())
        tableView.estimatedRowHeight = 41
        tableView.rowHeight = UITableView.automaticDimension

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 32
        tableView.separatorStyle = .none

        view.wmf_addSubviewWithConstraintsToEdges(tableView)

        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.semanticContentAttribute = self.semanticContentAttributeOverride

        view.semanticContentAttribute = semanticContentAttributeOverride

        
        apply(theme: theme)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.tableOfContentsControllerWillDisplay(self)
        tableOfContentsFunnel.logOpen()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deselectAllRows()
    }
    
    
    // MARK: - UITableViewDataSource
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WMFTableOfContentsCell.reuseIdentifier(), for: indexPath) as! WMFTableOfContentsCell
        let selectedItems: [TableOfContentsItem] = tableView.indexPathsForSelectedRows?.map() { items[$0.row] } ?? []
        let item = items[indexPath.row]
        let shouldHighlight = selectedItems.reduce(false) { shouldHighlight, selectedItem in
            shouldHighlight || item.shouldBeHighlightedAlongWithItem(selectedItem)
        }
        cell.backgroundColor = tableView.backgroundColor
        cell.contentView.backgroundColor = tableView.backgroundColor
        
        cell.titleIndentationLevel = item.indentationLevel
        cell.titleLabel.text = item.titleText
        cell.titleLabel.font = UIFont.wmf_font(item.itemType.titleTextStyle, compatibleWithTraitCollection: self.traitCollection)
        cell.selectionColor = theme.colors.link
        cell.titleColor = item.itemType == .primary ? theme.colors.primaryText : theme.colors.secondaryText
        
        cell.setNeedsLayout()

        cell.setSectionSelected(shouldHighlight, animated: false)
        
        cell.contentView.semanticContentAttribute = semanticContentAttributeOverride
        cell.titleLabel.semanticContentAttribute = semanticContentAttributeOverride
        
        return cell
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let delegate = delegate {
            let header = WMFTableOfContentsHeader.wmf_viewFromClassNib()
            header?.articleURL = delegate.tableOfContentsArticleLanguageURL()
            header?.backgroundColor = tableView.backgroundColor
            header?.semanticContentAttribute = semanticContentAttributeOverride
            header?.contentsLabel.semanticContentAttribute = semanticContentAttributeOverride
            header?.contentsLabel.textColor = theme.colors.secondaryText
            return header
        } else {
            return nil
        }
    }

    // MARK: - UITableViewDelegate

    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let item = items[indexPath.row]
        addHighlightToItem(item, animated: true)
        return true
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        tableOfContentsFunnel.logClick()
        addHighlightOfItemsRelatedTo(item, animated: true)
        delegate?.tableOfContentsController(self, didSelectItem: item)
    }

    open func tableOfContentsAnimatorDidTapBackground(_ controller: WMFTableOfContentsAnimator) {
        _ = didRequestClose(controller)
    }

    // MARK: - UIScrollViewDelegate
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let item = items[indexPath.row]
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
    
    public func apply(theme: Theme) {
        self.theme = theme
        self.animator?.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        if let delegate = delegate, delegate.tableOfContentsDisplayModeIsModal() {
            tableView.backgroundColor = theme.colors.paperBackground
        } else {
            tableView.backgroundColor = theme.colors.midBackground
        }
        tableView.reloadData()
    }
}

