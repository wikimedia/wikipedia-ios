
import UIKit

@objc public protocol WMFTableOfContentsViewControllerDelegate {
    func tableOfContentsController(controller: WMFTableOfContentsViewController, didSelectSection: MWKSection)
    func tableOfContentsControllerDidCancel(controller: WMFTableOfContentsViewController)
}

public class WMFTableOfContentsViewController: UITableViewController,
                                               UIViewControllerTransitioningDelegate,
                                               WMFTableOfContentsPresentationControllerTapDelegate  {
    let tableOfContentsFunnel: ToCInteractionFunnel

    weak var delegate: WMFTableOfContentsViewControllerDelegate?

    let sectionList: MWKSectionList

    // MARK: - init
    public required init(sectionList: MWKSectionList, delegate: WMFTableOfContentsViewControllerDelegate) {
        self.sectionList = sectionList
        self.delegate = delegate
        tableOfContentsFunnel = ToCInteractionFunnel.init()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Sections

    func sections() -> Array<MWKSection>? {
        return sectionList.entries as? Array<MWKSection>
    }
    
    func sectionAtIndexPath(indexPath: NSIndexPath) -> MWKSection? {
        guard indexPath.row < sections()?.count else {
            return nil
        }
        return sections()?[indexPath.row]
    }
    
    func indexPathForSection(section: MWKSection) -> NSIndexPath? {
        if let row = sections()?.indexOf(section) {
            return NSIndexPath.init(forRow: row, inSection: 0)
        } else {
            return nil
        }
    }
    
    // MARK: - Select and Scroll to Section
    public func scrollToSection(section: MWKSection, animated: Bool) {
        if let indexPath = indexPathForSection(section) {
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: animated)
        }
    }

    public func selectAndScrollToSection(section: MWKSection, animated: Bool) {
        if let indexPath = indexPathForSection(section) {
            removeSectionHighlightFromAllRows()
            tableView.selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition.Top)
            addSectionHighlightToSectionAndVisibleRowsIntheSameSectionAs(section, animated: false)
        }
    }
    
    // MARK: - Highlight Sections

    public func sectionShouldBeHighlighted(section: MWKSection) -> Bool {
        if let indexPath = tableView.indexPathForSelectedRow {
            if let selectedSection = sectionAtIndexPath(indexPath) {
                if selectedSection.sectionHasSameRootSection(section) {
                    return true
                }
            }
        }
        return false
    }
    
    public func removeSectionHighlightFromAllRows() {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, element) in visibleIndexPaths.enumerate() {
            if let cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(element) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(false, animated: false)
            }
        }
    }
    
    public func addSectionHighlightToSectionAndVisibleRowsIntheSameSectionAs(section: MWKSection, animated: Bool) {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, indexPath) in visibleIndexPaths.enumerate() {
            if let subSection = sectionAtIndexPath(indexPath) {
                if (subSection.sectionHasSameRootSection(section)) {
                    if let cell: WMFTableOfContentsCell = tableView.cellForRowAtIndexPath(indexPath) as? WMFTableOfContentsCell  {
                        cell.setSectionSelected(true, animated: animated)
                    }
                }
            }
        }
    }
    
    // MARK: - UIViewController

    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNib(WMFTableOfContentsCell.wmf_classNib(), forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier());
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
    
    // MARK: - UITableViewDataSource
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = sections() {
            return sections.count
        }else{
            return 0
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(WMFTableOfContentsCell.reuseIdentifier(), forIndexPath: indexPath) as! WMFTableOfContentsCell
        if let section = sectionAtIndexPath(indexPath) {
            cell.section = section
            cell.setSectionSelected(sectionShouldBeHighlighted(section), animated: false)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let section = sectionAtIndexPath(indexPath) {
            tableOfContentsFunnel.logClick()
            removeSectionHighlightFromAllRows()
            addSectionHighlightToSectionAndVisibleRowsIntheSameSectionAs(section, animated: true)
            delegate?.tableOfContentsController(self, didSelectSection: section)
        }
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
