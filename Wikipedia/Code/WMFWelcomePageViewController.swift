import Foundation
import UIKit

enum WMFWelcomePageType {
    case intro
    case languages
    case analytics
}

public protocol WMFWelcomeNavigationDelegate: class{
    func showNextWelcomePage(sender: AnyObject)
}

class WMFWelcomePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, WMFWelcomeNavigationDelegate {

    var completionBlock: (() -> Void)?
    
    func showNextWelcomePage(sender: AnyObject){
        let index = pageControllers.indexOf(sender as! UIViewController)
        if index == pageControllers.count - 1 {
            dismissViewControllerAnimated(true, completion:completionBlock)
        }else{
            view.userInteractionEnabled = false
            let nextIndex = index! + 1

            let direction:UIPageViewControllerNavigationDirection = UIApplication.sharedApplication().wmf_isRTL ? .Reverse : .Forward
            self.setViewControllers([pageControllers[nextIndex]], direction: direction, animated: true, completion: {(Bool) in
                self.view.userInteractionEnabled = true
            })
        }
    }

    private func containerControllerForWelcomePageType(type: WMFWelcomePageType) -> WMFWelcomeContainerViewController {
        let controller = WMFWelcomeContainerViewController.wmf_viewControllerFromWelcomeStoryboard()
        controller.welcomeNavigationDelegate = self
        controller.welcomePageType = type
        return controller
    }
    
    private lazy var pageControllers: [UIViewController] = {
        var controllers:[UIViewController] = []
        controllers.append(self.containerControllerForWelcomePageType(.intro))
        controllers.append(self.containerControllerForWelcomePageType(.languages))
        controllers.append(self.containerControllerForWelcomePageType(.analytics))
        return controllers
    }()
    
    private lazy var pageControl: UIPageControl? = {
        return self.view.wmf_firstSubviewOfType(UIPageControl)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        let direction:UIPageViewControllerNavigationDirection = UIApplication.sharedApplication().wmf_isRTL ? .Forward : .Reverse
        
        setViewControllers([pageControllers.first!], direction: direction, animated: true, completion: nil)

        addGradient()
        
        if let scrollView = view.wmf_firstSubviewOfType(UIScrollView) {
            scrollView.clipsToBounds = false
        }
    }

    private func addGradient() {
        let gradientView = backgroundGradient()
        view.insertSubview(gradientView, atIndex: 0)
        gradientView.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
    }

    private func backgroundGradient() -> WMFGradientView {
        let gradient = WMFGradientView.init()
        gradient.gradientLayer.locations = [0, 1]
        gradient.gradientLayer.colors =  [UIColor.wmf_welcomeBackgroundGradientBottomColor().CGColor, UIColor.wmf_welcomeBackgroundGradientTopColor().CGColor]
        gradient.gradientLayer.startPoint = CGPoint.init(x: 0.5, y: 1.0)
        gradient.gradientLayer.endPoint = CGPoint.init(x: 0.5, y: 0.0)
        gradient.userInteractionEnabled = false
        return gradient
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let pageControl = pageControl {
            pageControl.userInteractionEnabled = false
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }

    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return .Portrait
    }

    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // MARK: - iOS 9 RTL swiping hack
    // When *swiping* side-to-side to move between panels on RTL with iOS 9 the dots get out of sync... not sure why. 
    // This hack sets the correct dot, but first fades the dots out so you don't see it flicker to the wrong dot then the right one.
    
    private func isRTLiOS9() -> Bool {
        return UIApplication.sharedApplication().wmf_isRTL && NSProcessInfo.processInfo().wmf_isOperatingSystemMajorVersionLessThan(10)
    }
    
    func animateIfRightToLeftAndiOS9(animations: () -> Void) {
        if isRTLiOS9() {
            UIView.animateWithDuration(0.05, delay: 0.0, options: .CurveEaseOut, animations:animations, completion:nil)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        animateIfRightToLeftAndiOS9({
            if let pageControl = self.pageControl {
                pageControl.alpha = CGFloat(0.0)
            }
        })
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool){
        animateIfRightToLeftAndiOS9({
            if let pageControl = self.pageControl {
                pageControl.currentPage = self.presentationIndexForPageViewController(pageViewController)
                pageControl.alpha = CGFloat(1.0)
            }
        })
    }
}
