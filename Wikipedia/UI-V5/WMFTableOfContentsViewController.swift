
import UIKit

// MARK: - Delegate
@objc public protocol WMFTableOfContentsViewControllerDelegate {
    
    func tableOfContentsController(controller: WMFTableOfContentsViewController, didSelectSection: MWKSection)
    func tableOfContentsControllerDidCancel(controller: WMFTableOfContentsViewController)
}


// MARK: - Controller
public class WMFTableOfContentsViewController: UITableViewController, UIViewControllerTransitioningDelegate, WMFTableOfContentsPresentationControllerTapDelegate  {
    
    // MARK: - init
    public required init(sectionList: MWKSectionList, delegate: WMFTableOfContentsViewControllerDelegate) {
        self.sectionList = sectionList
        self.delegate = delegate
        self.tableOfContentsFunnel = ToCInteractionFunnel.init()
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let tableOfContentsFunnel: ToCInteractionFunnel

    weak var delegate: WMFTableOfContentsViewControllerDelegate?

    
    // MARK: - Sections
    let sectionList: MWKSectionList
    
    func sections() -> Array<MWKSection>? {
        return self.sectionList.entries as? Array<MWKSection>
    }

    func sectionAtIndexPath(indexPath: NSIndexPath) -> MWKSection? {
        guard indexPath.row < self.sections()?.count else {
            return nil
        }
        return self.sections()?[indexPath.row]
    }
    
    func indexPathForSection(section: MWKSection) -> NSIndexPath? {
        if let row = self.sections()?.indexOf(section) {
            return NSIndexPath.init(forRow: row, inSection: 0)
        } else {
            return nil
        }
    }
    
    // MARK: - Select and Scroll to Section
    public func scrollToSection(section: MWKSection, animated: Bool) {
        if let indexPath = self.indexPathForSection(section) {
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: animated)
        }
    }

    public func selectAndScrollToSection(section: MWKSection, animated: Bool) {
        if let indexPath = self.indexPathForSection(section) {
            self.removeSectionHighlightFromAllRows()
            self.tableView.selectRowAtIndexPath(indexPath, animated: animated, scrollPosition: UITableViewScrollPosition.Top)
            self.addSectionHighlightToSectionAndVisibleRowsIntheSameSectionAs(section, animated: false)
        }
    }
    
    // MARK: - Highlight Sections
    public func sectionShouldBeHighlighted(section: MWKSection) -> Bool {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            if let selectedSection = self.sectionAtIndexPath(indexPath) {
                if selectedSection.sectionHasSameRootSection(section) {
                    return true
                }
            }
        }
        return false
    }
    
    public func removeSectionHighlightFromAllRows() {
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, element) in visibleIndexPaths.enumerate() {
            if let cell: WMFTableOfContentsCell = self.tableView.cellForRowAtIndexPath(element) as? WMFTableOfContentsCell  {
                cell.setSectionSelected(false, animated: false)
            }
        }
    }
    
    public func addSectionHighlightToSectionAndVisibleRowsIntheSameSectionAs(section: MWKSection, animated: Bool) {
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows else {
            return
        }
        for (_, indexPath) in visibleIndexPaths.enumerate() {
            if let subSection = self.sectionAtIndexPath(indexPath) {
                if (subSection.sectionHasSameRootSection(section)) {
                    if let cell: WMFTableOfContentsCell = self.tableView.cellForRowAtIndexPath(indexPath) as? WMFTableOfContentsCell  {
                        cell.setSectionSelected(true, animated: animated)
                    }
                }
            }
        }
    }
    
    // MARK: - UIViewController
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerNib(WMFTableOfContentsCell.wmf_classNib(), forCellReuseIdentifier: WMFTableOfContentsCell.reuseIdentifier());
        self.clearsSelectionOnViewWillAppear = false
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.size.height, 0, 0, 0)
        self.tableView.separatorStyle = .None
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableOfContentsFunnel.logOpen()
    }
    
    // MARK: - UITableViewDataSource
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = self.sections() {
            return sections.count
        }else{
            return 0
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(WMFTableOfContentsCell.reuseIdentifier(), forIndexPath: indexPath) as! WMFTableOfContentsCell
        if let section = self.sectionAtIndexPath(indexPath) {
            cell.section = section
            cell.setSectionSelected(self.sectionShouldBeHighlighted(section), animated: false)
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let section = self.sectionAtIndexPath(indexPath) {
            self.tableOfContentsFunnel.logClick()
            self.removeSectionHighlightFromAllRows()
            self.addSectionHighlightToSectionAndVisibleRowsIntheSameSectionAs(section, animated: true)
            self.delegate?.tableOfContentsController(self, didSelectSection: section)
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
        self.tableOfContentsFunnel.logClose()
        self.delegate?.tableOfContentsControllerDidCancel(self)
    }

    

}
