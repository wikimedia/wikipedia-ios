import UIKit

@objc (WMFNavigationBarHiderDelegate)
public protocol NavigationBarHiderDelegate: NSObjectProtocol {
    func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool)
}

@objc(WMFNavigationBarHider)
public class NavigationBarHider: NSObject, UIScrollViewDelegate {
    @objc public weak var navigationBar: NavigationBar?
    @objc public weak var delegate: NavigationBarHiderDelegate?
    
    fileprivate var isUserScrolling: Bool = false
    var initialScrollY: CGFloat = 0
    
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
        initialScrollY = scrollView.contentOffset.y + scrollView.contentInset.top
    }
    

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, isUserScrolling else {
            return
        }
        
        let animated = false

        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        var extendedViewPercentHidden = currentExtendedViewPercentHidden
        var navigationBarPercentHidden = currentNavigationBarPercentHidden

        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        
        let extendedViewHeight = navigationBar.extendedView.frame.size.height
        if extendedViewHeight > 0 {
            extendedViewPercentHidden = min(max(0, scrollY/extendedViewHeight), 1)
        }
        
        let barHeight = navigationBar.bar.frame.size.height
        if scrollY >= extendedViewHeight {
            navigationBarPercentHidden = min(max(0, (scrollY - extendedViewHeight)/barHeight), 1)
        }

        guard currentExtendedViewPercentHidden != extendedViewPercentHidden || currentNavigationBarPercentHidden !=  navigationBarPercentHidden else {
            return
        }
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isUserScrolling else {
            return
        }
        
        isUserScrolling = false
        
        guard let navigationBar = navigationBar else {
            return
        }
        
        let extendedViewHeight = navigationBar.extendedView.frame.size.height
        let barHeight = navigationBar.bar.frame.size.height
        
        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        var extendedViewPercentHidden: CGFloat = currentExtendedViewPercentHidden
        
        if currentExtendedViewPercentHidden > 0 && currentExtendedViewPercentHidden < 0.5 {
            extendedViewPercentHidden = 0
        } else if currentExtendedViewPercentHidden > 0.5 && currentExtendedViewPercentHidden < 1 {
            extendedViewPercentHidden = 1
        }
        
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        var navigationBarPercentHidden: CGFloat = currentNavigationBarPercentHidden
        
        if currentNavigationBarPercentHidden > 0 && currentNavigationBarPercentHidden < 0.5 {
            navigationBarPercentHidden = 0
        } else if currentNavigationBarPercentHidden > 0.5 && currentNavigationBarPercentHidden < 1 {
            navigationBarPercentHidden = 1
        }
        
        guard currentExtendedViewPercentHidden != extendedViewPercentHidden || currentNavigationBarPercentHidden !=  navigationBarPercentHidden else {
            return
        }
        let targetOffsetY = targetContentOffset.pointee.y
        let top = 0 - scrollView.contentInset.top
        if targetOffsetY < top + extendedViewHeight + barHeight {
            if extendedViewPercentHidden == 0 && navigationBarPercentHidden == 0 { // both visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top)
            } else if navigationBarPercentHidden == 0  { // only nav bar visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight)
            } else { //neither visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + barHeight)
            }
        }

        let animated = true
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
}
