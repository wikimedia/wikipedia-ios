import Foundation
import UIKit

@objc public protocol WMFWelcomeNavigationDelegate{
    func showNextWelcomePage(sender: AnyObject)
}

class WMFWelcomePageViewController: UIPageViewController, UIPageViewControllerDataSource, WMFWelcomeNavigationDelegate {

    var completionBlock: (() -> Void)?
    var indexForDotIndicator:Int = 0
    
    func showNextWelcomePage(sender: AnyObject){
        let index = pageControllers.indexOf(sender as! UIViewController)
        if index == pageControllers.count - 1 {
            self.dismissViewControllerAnimated(true, completion:completionBlock)
        }else{
            let nextIndex = index! + 1
            indexForDotIndicator = nextIndex
            self.setViewControllers([pageControllers[nextIndex]], direction: .Forward, animated: true, completion: nil)
        }
    }
    
    private let pageControllers:[UIViewController] = [
        WMFWelcomeIntroductionViewController.wmf_viewControllerWithIdentifier("WMFWelcomeIntroductionViewController", fromStoryboardNamed: "WMFWelcome"),
        WMFWelcomeLanguageViewController.wmf_viewControllerWithIdentifier("WMFWelcomeLanguageViewController", fromStoryboardNamed: "WMFWelcome"),
        WMFWelcomeAnalyticsViewController.wmf_viewControllerWithIdentifier("WMFWelcomeAnalyticsViewController", fromStoryboardNamed: "WMFWelcome")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.setViewControllers([pageControllers.first!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)

        for controller in pageControllers {
            controller.view.backgroundColor = UIColor.clearColor()
            let controller = controller as! WMFWelcomeFadeInAndUpOnceViewController
            controller.delegate = self
        }

        let gradientView = WMFGradientView.init()
        gradientView.gradientLayer.locations = [0, 1]
        gradientView.gradientLayer.colors =  [UIColor.wmf_welcomeBackgroundGradientBottomColor().CGColor, UIColor.wmf_welcomeBackgroundGradientTopColor().CGColor]
        gradientView.gradientLayer.startPoint = CGPoint.init(x: 0.5, y: 1.0)
        gradientView.gradientLayer.endPoint = CGPoint.init(x: 0.5, y: 0.0)
        gradientView.userInteractionEnabled = false
        view.insertSubview(gradientView, atIndex: 0)
        gradientView.mas_makeConstraints { make in
            make.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
        if let scrollView = view.wmf_firstSubviewOfType(UIScrollView) {
            scrollView.clipsToBounds = false
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let pageControl = view.wmf_firstSubviewOfType(UIPageControl) {
            pageControl.userInteractionEnabled = false
        }
    }

    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return indexForDotIndicator;
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let index = pageControllers.indexOf(viewController)
        if index == nil || index! + 1 == pageControllers.count {
            return nil
        } else {
            return pageControllers[index! + 1]
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let index = pageControllers.indexOf(viewController)
        if index == nil || index! == 0 {
            return nil
        } else {
            return pageControllers[index! - 1]
        }
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
}
