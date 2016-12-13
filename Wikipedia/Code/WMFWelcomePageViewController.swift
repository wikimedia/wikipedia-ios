import Foundation
import UIKit

enum WMFWelcomePageType {
    case intro
    case languages
    case analytics
}

public protocol WMFWelcomeNavigationDelegate: class{
    func showNextWelcomePage(_ sender: AnyObject)
}

class WMFWelcomePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, WMFWelcomeNavigationDelegate {

    var completionBlock: (() -> Void)?
    
    func showNextWelcomePage(_ sender: AnyObject){
        let index = pageControllers.index(of: sender as! UIViewController)
        if index == pageControllers.count - 1 {
            dismiss(animated: true, completion:completionBlock)
        }else{
            view.isUserInteractionEnabled = false
            let nextIndex = index! + 1

            let direction:UIPageViewControllerNavigationDirection = UIApplication.shared.wmf_isRTL ? .reverse : .forward
            self.setViewControllers([pageControllers[nextIndex]], direction: direction, animated: true, completion: {(Bool) in
                self.view.isUserInteractionEnabled = true
            })
        }
    }

    fileprivate func containerControllerForWelcomePageType(_ type: WMFWelcomePageType) -> WMFWelcomeContainerViewController {
        let controller = WMFWelcomeContainerViewController.wmf_viewControllerFromWelcomeStoryboard()
        controller.welcomeNavigationDelegate = self
        controller.welcomePageType = type
        return controller
    }
    
    fileprivate lazy var pageControllers: [UIViewController] = {
        var controllers:[UIViewController] = []
        controllers.append(self.containerControllerForWelcomePageType(.intro))
        controllers.append(self.containerControllerForWelcomePageType(.languages))
        controllers.append(self.containerControllerForWelcomePageType(.analytics))
        return controllers
    }()
    
    fileprivate lazy var pageControl: UIPageControl? = {
        return self.view.wmf_firstSubviewOfType(UIPageControl.self)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        
        let direction:UIPageViewControllerNavigationDirection = UIApplication.shared.wmf_isRTL ? .forward : .reverse
        
        setViewControllers([pageControllers.first!], direction: direction, animated: true, completion: nil)

        addGradient()
        
        if let scrollView = view.wmf_firstSubviewOfType(UIScrollView.self) {
            scrollView.clipsToBounds = false
        }
    }

    fileprivate func addGradient() {
        let gradientView = backgroundGradient()
        view.insertSubview(gradientView, at: 0)
        gradientView.mas_makeConstraints { make in
            _ = make?.top.bottom().leading().and().trailing().equalTo()(self.view)
        }
    }

    fileprivate func backgroundGradient() -> WMFGradientView {
        let gradient = WMFGradientView.init()
        gradient.gradientLayer.locations = [0, 1]
        gradient.gradientLayer.colors =  [UIColor.wmf_welcomeBackgroundGradientBottom().cgColor, UIColor.wmf_welcomeBackgroundGradientTop().cgColor]
        gradient.gradientLayer.startPoint = CGPoint.init(x: 0.5, y: 1.0)
        gradient.gradientLayer.endPoint = CGPoint.init(x: 0.5, y: 0.0)
        gradient.isUserInteractionEnabled = false
        return gradient
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pageControl = pageControl {
            pageControl.isUserInteractionEnabled = false
        }
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pageControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let viewControllers = viewControllers, let currentVC = viewControllers.first, let presentationIndex = pageControllers.index(of: currentVC) else {
            return 0
        }
        return presentationIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pageControllers.index(of: viewController) else {
            return nil
        }
        return index >= pageControllers.count - 1 ? nil : pageControllers[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pageControllers.index(of: viewController) else {
            return nil
        }
        return index == 0 ? nil : pageControllers[index - 1]
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .portrait
    }

    override var shouldAutorotate : Bool {
        return false
    }
    
    // MARK: - iOS 9 RTL swiping hack
    // When *swiping* side-to-side to move between panels on RTL with iOS 9 the dots get out of sync... not sure why. 
    // This hack sets the correct dot, but first fades the dots out so you don't see it flicker to the wrong dot then the right one.
    
    fileprivate func isRTLiOS9() -> Bool {
        return UIApplication.shared.wmf_isRTL && ProcessInfo().wmf_isOperatingSystemMajorVersionLessThan(10)
    }
    
    func animateIfRightToLeftAndiOS9(_ animations: @escaping () -> Void) {
        if isRTLiOS9() {
            UIView.animate(withDuration: 0.05, delay: 0.0, options: .curveEaseOut, animations:animations, completion:nil)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        animateIfRightToLeftAndiOS9({
            if let pageControl = self.pageControl {
                pageControl.alpha = CGFloat(0.0)
            }
        })
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool){
        animateIfRightToLeftAndiOS9({
            if let pageControl = self.pageControl {
                pageControl.currentPage = self.presentationIndex(for: pageViewController)
                pageControl.alpha = CGFloat(1.0)
            }
        })
    }
}
