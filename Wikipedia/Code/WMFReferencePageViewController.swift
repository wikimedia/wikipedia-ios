
import Foundation

extension UIViewController {
    class func wmf_viewControllerFromReferencePanelsStoryboard() -> Self {
        return self.wmf_viewControllerFromStoryboardNamed("WMFReferencePanels")
    }
}

class WMFReferencePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var lastClickedReferencesIndex:Int = 0
    var lastClickedReferencesGroup = [[String: AnyObject]]()
    
    private lazy var pageControllers: [UIViewController] = {
        var controllers:[UIViewController] = []
        
        for referenceDictionary in self.lastClickedReferencesGroup {
            let panel = WMFReferencePanelViewController.wmf_viewControllerFromReferencePanelsStoryboard()
            panel.referenceDictionary = referenceDictionary
            controllers.append(panel)
        }
        
        return controllers
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        let direction:UIPageViewControllerNavigationDirection = UIApplication.sharedApplication().wmf_isRTL ? .Forward : .Reverse
        
        let initiallyVisibleController = pageControllers[lastClickedReferencesIndex]
        
        setViewControllers([initiallyVisibleController], direction: direction, animated: true, completion: nil)
        
        view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        
        if let scrollView = view.wmf_firstSubviewOfType(UIScrollView) {
            scrollView.clipsToBounds = false
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        guard let viewControllers = viewControllers, currentVC = viewControllers.first, presentationIndex = pageControllers.indexOf(currentVC) else {
            return 0
        }
        return presentationIndex
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let index = pageControllers.indexOf(viewController) else {
            return nil
        }
        return index >= pageControllers.count - 1 ? nil : pageControllers[index + 1]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let index = pageControllers.indexOf(viewController) else {
            return nil
        }
        return index == 0 ? nil : pageControllers[index - 1]
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        self.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
}
