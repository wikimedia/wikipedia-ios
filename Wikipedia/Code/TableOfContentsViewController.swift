import UIKit
import WMF

enum TableOfContentsDisplayMode {
    case inline
    case modal
}

enum TableOfContentsDisplaySide {
    case left
    case right
}


protocol TableOfContentsViewControllerDelegate : UIViewController {

    /**
     Notifies the delegate that the controller will display
     Use this to update the ToC if needed
     */
    func tableOfContentsControllerWillDisplay(_ controller: TableOfContentsViewController)

    /**
     The delegate is responsible for dismissing the view controller
     */
    func tableOfContentsController(_ controller: TableOfContentsViewController,
                                   didSelectItem item: TableOfContentsItem)

    /**
     The delegate is responsible for dismissing the view controller
     */
    func tableOfContentsControllerDidCancel(_ controller: TableOfContentsViewController)

    var tableOfContentsArticleLanguageURL: URL? { get }
        
    var tableOfContentsSemanticContentAttribute: UISemanticContentAttribute { get }
    
    var tableOfContentsItems: [TableOfContentsItem] { get }
}

class TableOfContentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TableOfContentsAnimatorDelegate, Themeable {
    
    fileprivate var theme = Theme.standard

    var semanticContentAttributeOverride: UISemanticContentAttribute {
        return delegate?.tableOfContentsSemanticContentAttribute ?? .unspecified
    }
    
    let displaySide: TableOfContentsDisplaySide
    
    var displayMode = TableOfContentsDisplayMode.modal {
        didSet {
            animator?.displayMode = displayMode
            closeGestureRecognizer?.isEnabled = displayMode == .inline
            apply(theme: theme)
        }
    }
    
    var isVisible: Bool = false
    
    var closeGestureRecognizer: UISwipeGestureRecognizer?
    
    @objc func handleTableOfContentsCloseGesture(_ swipeGestureRecoginzer: UIGestureRecognizer) {
        guard swipeGestureRecoginzer.state == .ended, isVisible else {
            return
        }
        delegate?.tableOfContentsControllerDidCancel(self)
    }

    let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
    
    lazy var animator: TableOfContentsAnimator? = {
        guard let delegate = delegate else {
            return nil
        }
        let animator = TableOfContentsAnimator(presentingViewController: delegate, presentedViewController: self)
        animator.apply(theme: theme)
        animator.delegate = self
        animator.displaySide = displaySide
        animator.displayMode = displayMode
        return animator
    }()

    weak var delegate: TableOfContentsViewControllerDelegate?
    
    var items: [TableOfContentsItem] {
        return delegate?.tableOfContentsItems ?? []
    }
    
    func reload() {
        tableView.reloadData()
        selectInitialItemIfNecessary()
    }

    // MARK: - Init
    required init(delegate: TableOfContentsViewControllerDelegate?, theme: Theme, displaySide: TableOfContentsDisplaySide) {
        self.theme = theme
        self.delegate = delegate
        self.displaySide = displaySide
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = animator
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Sections

    var indexOfSelectedItem: Int = -1
    var indiciesOfHighlightedItems: Set<Int> = []

    func selectInitialItemIfNecessary() {
        guard indexOfSelectedItem == -1, !items.isEmpty else {
            return
        }
        selectItem(at: 0)
    }
    
    func selectItem(at index: Int) {
        guard index < items.count else {
            assertionFailure("Trying to select an item out of range")
            return
        }
        
        guard indexOfSelectedItem != index else {
            return
        }
        
        indexOfSelectedItem = index
        
        var newIndicies: Set<Int> = [index]
        let item = items[index]
        for (index, relatedItem) in items.enumerated() {
            guard item.shouldBeHighlightedAlongWithItem(relatedItem) else {
                continue
            }
            newIndicies.insert(index)
        }
        guard newIndicies != indiciesOfHighlightedItems else {
            return
        }
        
        let indiciesToReload = newIndicies.union(indiciesOfHighlightedItems)
        let indexPathsToReload = indiciesToReload.map { IndexPath(row: $0, section: 0) }
        indiciesOfHighlightedItems = newIndicies
        
        guard viewIfLoaded != nil else {
            return
        }
        tableView.reloadRows(at: indexPathsToReload, with: .none)
    }
    
    func scrollToItem(at index: Int) {
        guard index < items.count else {
            assertionFailure("Trying to scroll to an item put of range")
            return
        }
        guard viewIfLoaded != nil, index < tableView.numberOfRows(inSection: 0) else {
            return
        }
        let indexPath = IndexPath(row: index, section: 0)
        guard !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? true) else {
            return
        }
        let shouldAnimate = (displayMode == .inline)
        tableView.scrollToRow(at: indexPath, at: .top, animated: shouldAnimate)
    }

    // MARK: - Selection
    
    private func didRequestClose(_ controller: TableOfContentsAnimator?) -> Bool {
        delegate?.tableOfContentsControllerDidCancel(self)
        return delegate != nil
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(tableView.style == .grouped, "Use grouped UITableView layout so our TableOfContentsHeader's autolayout works properly. Formerly we used a .Plain table style and set self.tableView.tableHeaderView to our TableOfContentsHeader, but doing so caused autolayout issues for unknown reasons. Instead, we now use a grouped layout and use TableOfContentsHeader with viewForHeaderInSection, which plays nicely with autolayout. (grouped layouts also used because they allow the header to scroll *with* the section cells rather than floating)")

        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = nil

        tableView.register(TableOfContentsCell.wmf_classNib(),
                    forCellReuseIdentifier: TableOfContentsCell.reuseIdentifier())
        tableView.estimatedRowHeight = 41
        tableView.rowHeight = UITableView.automaticDimension

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 32
        tableView.separatorStyle = .none

        view.wmf_addSubviewWithConstraintsToEdges(tableView)

        tableView.contentInsetAdjustmentBehavior = .never
        tableView.allowsMultipleSelection = false
        tableView.semanticContentAttribute = delegate?.tableOfContentsSemanticContentAttribute ?? .unspecified

        view.semanticContentAttribute = delegate?.tableOfContentsSemanticContentAttribute ?? .unspecified

        let closeGR = UISwipeGestureRecognizer(target: self, action: #selector(handleTableOfContentsCloseGesture))
        switch displaySide {
        case .left:
            closeGR.direction = .left
        case .right:
            closeGR.direction = .right
        }
        view.addGestureRecognizer(closeGR)
        closeGestureRecognizer = closeGR
        
        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.tableOfContentsControllerWillDisplay(self)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TableOfContentsCell.reuseIdentifier(), for: indexPath) as! TableOfContentsCell

        let index = indexPath.row
        
        let item = items[index]
        
        let shouldHighlight = indiciesOfHighlightedItems.contains(index)
        
        cell.backgroundColor = tableView.backgroundColor
        cell.contentView.backgroundColor = tableView.backgroundColor
        
        cell.titleIndentationLevel = item.indentationLevel
        let color = item.itemType == .primary ? theme.colors.primaryText : theme.colors.secondaryText
        let selectionColor = theme.colors.link
        let isHighlighted = index == indexOfSelectedItem
        cell.setTitleHTML(item.titleHTML, with: item.itemType.titleTextStyle, highlighted: isHighlighted, color: color, selectionColor: selectionColor)

        if isHighlighted {
            // This makes no difference to sighted users; it allows VoiceOver to read highlighted cell as selected.
            cell.accessibilityTraits = .selected
        }
        
        cell.setNeedsLayout()

        cell.setSectionSelected(shouldHighlight, animated: false)
        
        cell.contentView.semanticContentAttribute = semanticContentAttributeOverride
        cell.titleLabel.semanticContentAttribute = semanticContentAttributeOverride
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let delegate = delegate {
            let header = TableOfContentsHeader.wmf_viewFromClassNib()
            header?.articleURL = delegate.tableOfContentsArticleLanguageURL
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.row
        selectItem(at: index)
        delegate?.tableOfContentsController(self, didSelectItem: items[index])
    }

    func tableOfContentsAnimatorDidTapBackground(_ controller: TableOfContentsAnimator) {
        _ = didRequestClose(controller)
    }

    // MARK: - UIAccessibilityAction
    override func accessibilityPerformEscape() -> Bool {
        return didRequestClose(nil)
    }
    
    // MARK: - UIAccessibilityAction
    override func accessibilityPerformMagicTap() -> Bool {
        return didRequestClose(nil)
    }
    
    public func apply(theme: Theme) {
        self.theme = theme
        self.animator?.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        if displayMode == .modal {
            tableView.backgroundColor = theme.colors.paperBackground
        } else {
            tableView.backgroundColor = theme.colors.midBackground
        }
        tableView.reloadData()
    }
}

