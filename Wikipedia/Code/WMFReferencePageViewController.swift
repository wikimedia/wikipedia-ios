
import Foundation

extension UIViewController {
    class func wmf_viewControllerFromReferencePanelsStoryboard() -> Self {
        return self.wmf_viewControllerFromStoryboardNamed("WMFReferencePanels")
    }
}

@objc protocol WMFReferencePageViewAppearanceDelegate : NSObjectProtocol {
    func referencePageViewControllerWillAppear(referencePageViewController: WMFReferencePageViewController)
    func referencePageViewControllerWillDisappear(referencePageViewController: WMFReferencePageViewController)
}

class WMFReferencePageViewController: UIPageViewController, UIPageViewControllerDataSource {
    var lastClickedReferencesIndex:Int = 0
    var lastClickedReferencesGroup = [WMFReference]()
    
    weak internal var appearanceDelegate: WMFReferencePageViewAppearanceDelegate?
    
    private lazy var pageControllers: [UIViewController] = {
        var controllers:[UIViewController] = []
        
        for reference in self.lastClickedReferencesGroup {
            let panel = WMFReferencePanelViewController.wmf_viewControllerFromReferencePanelsStoryboard()
            panel.reference = reference
            controllers.append(panel)
        }
        
        return controllers
    }()
    
    lazy var backgroundView: WMFReferencePageBackgroundView = {
        return WMFReferencePageBackgroundView()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        let direction:UIPageViewControllerNavigationDirection = UIApplication.sharedApplication().wmf_isRTL ? .Forward : .Reverse
        
        let initiallyVisibleController = pageControllers[lastClickedReferencesIndex]
        
        setViewControllers([initiallyVisibleController], direction: direction, animated: true, completion: nil)
        
        addBackgroundView()

        if let scrollView = view.wmf_firstSubviewOfType(UIScrollView) {
            scrollView.clipsToBounds = false
        }
    }
    
    private func addBackgroundView() {
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        backgroundView.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
    }
    
    internal func firstPanelView() -> UIView? {
        guard let viewControllers = viewControllers, firstVC = viewControllers.first as? WMFReferencePanelViewController else {
            return nil
        }
        return firstVC.containerView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        appearanceDelegate?.referencePageViewControllerWillAppear(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        appearanceDelegate?.referencePageViewControllerWillDisappear(self)
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
