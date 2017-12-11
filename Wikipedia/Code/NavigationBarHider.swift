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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, isUserScrolling else {
            return
        }
        
        let extendedViewHeight = navigationBar.extendedView.frame.size.height
        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        
        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let extendedViewPercentHidden = min(max(0, scrollY/extendedViewHeight), 1)
        
        // no change in scrollY
        if (scrollY == 0) {
            return
        }
        
        if (currentExtendedViewPercentHidden == extendedViewPercentHidden) {
            return
        }
        let navigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        let animated = false
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let navigationBar = navigationBar else {
            return
        }
        let velocity = velocity.y
        guard velocity != 0 else { // don't hide or show on 0 velocity tap
            return
        }
        let navigationBarPercentHidden: CGFloat = velocity > 0 ? 1 : 0
        guard navigationBarPercentHidden != navigationBar.navigationBarPercentHidden else {
            return
        }
        let extendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let animated = true
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        defer {
            isUserScrolling = false
        }
        
        guard let navigationBar = navigationBar else {
            return
        }
        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        
        var updatedExtendedViewPercentHidden: CGFloat?
        if (currentExtendedViewPercentHidden > 0 && currentExtendedViewPercentHidden < 0.5) {
            updatedExtendedViewPercentHidden = 0
        } else if (currentExtendedViewPercentHidden > 0.5 && currentExtendedViewPercentHidden < 1) {
            updatedExtendedViewPercentHidden = 1
        }
        
        guard let extendedViewPercentHidden = updatedExtendedViewPercentHidden else {
            return
        }
        
        let navigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        let extendedViewHeight = navigationBar.extendedView.frame.height
        let animated = true
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            if extendedViewPercentHidden < 1 {
                scrollView.setContentOffset(CGPoint(x: 0, y: 0 - scrollView.contentInset.top), animated: false)
            } else {
                scrollView.setContentOffset(CGPoint(x: 0, y: 0 - scrollView.contentInset.top + extendedViewHeight), animated: false)
            }
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
}
