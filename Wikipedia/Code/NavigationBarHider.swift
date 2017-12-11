import UIKit

@objc (WMFNavigationBarHiderDelegate)
public protocol NavigationBarHiderDelegate: NSObjectProtocol {
    func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool)
}


extension CGFloat {
    func wmf_adjustedForRange(_ lower: CGFloat, upper: CGFloat, step: CGFloat) -> CGFloat {
        if self < lower + step {
            return lower
        } else if self > upper - step {
            return upper
        } else if isNaN || isInfinite {
            return lower
        } else {
            return self
        }
    }

    var wmf_normalizedPercentage: CGFloat {
        return wmf_adjustedForRange(0, upper: 1, step: 0.01)
    }
}


@objc(WMFNavigationBarHider)
public class NavigationBarHider: NSObject {
    @objc public weak var navigationBar: NavigationBar?
    @objc public weak var delegate: NavigationBarHiderDelegate?
    
    fileprivate var isUserScrolling: Bool = false
    var initialScrollY: CGFloat = 0
    var initialNavigationBarPercentHidden: CGFloat = 0
    
    @objc public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar else {
            return
        }
        isUserScrolling = true
        initialScrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        initialNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
    }

    @objc public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar else {
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
            extendedViewPercentHidden = (scrollY/extendedViewHeight).wmf_normalizedPercentage
        }
        
        let barHeight = navigationBar.bar.frame.size.height
        if initialScrollY < extendedViewHeight + barHeight || scrollY <= extendedViewHeight + barHeight {
            navigationBarPercentHidden = ((scrollY - extendedViewHeight)/barHeight).wmf_normalizedPercentage
        } else if initialNavigationBarPercentHidden == 0 && initialScrollY > extendedViewHeight + barHeight {
            navigationBarPercentHidden = ((scrollY - initialScrollY)/barHeight).wmf_normalizedPercentage
        }

        guard currentExtendedViewPercentHidden != extendedViewPercentHidden || currentNavigationBarPercentHidden !=  navigationBarPercentHidden else {
            return
        }
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    @objc public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isUserScrolling else {
            return
        }
        
        isUserScrolling = false
        
        guard let navigationBar = navigationBar else {
            return
        }
        
        let extendedViewHeight = navigationBar.extendedView.frame.size.height
        let barHeight = navigationBar.bar.frame.size.height

        let top = 0 - scrollView.contentInset.top
        let targetOffsetY = targetContentOffset.pointee.y - top
        if targetOffsetY < extendedViewHeight + barHeight {
            if targetOffsetY < 0.5 * extendedViewHeight { // both visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top)
            } else if targetOffsetY < extendedViewHeight + 0.5 * barHeight  { // only nav bar visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight)
            } else if targetOffsetY < extendedViewHeight + barHeight {
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + barHeight)
            }
            return
        }
        
        if initialScrollY < extendedViewHeight + barHeight && targetOffsetY > extendedViewHeight + barHeight { // let it naturally hide
            return
        }

        let animated = true

        let extendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        var navigationBarPercentHidden: CGFloat = currentNavigationBarPercentHidden
        if velocity.y > 0 {
            navigationBarPercentHidden = 1
        } else if velocity.y < 0 {
            navigationBarPercentHidden = 0
        } else if navigationBarPercentHidden < 0.5 {
            navigationBarPercentHidden = 0
        } else {
            navigationBarPercentHidden = 1
        }

        guard navigationBarPercentHidden != currentNavigationBarPercentHidden else {
            return
        }

        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
}
