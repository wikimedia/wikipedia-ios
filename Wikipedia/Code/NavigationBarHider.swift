import UIKit

@objc (WMFNavigationBarHiderDelegate)
public protocol NavigationBarHiderDelegate: NSObjectProtocol {
    func navigationBarHider(_ hider: NavigationBarHider, didSetNavigationBarPercentHidden: CGFloat, underBarViewPercentHidden: CGFloat, extendedViewPercentHidden: CGFloat, animated: Bool)
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
    fileprivate var isScrollingToTop: Bool = false
    var initialScrollY: CGFloat = 0
    var initialNavigationBarPercentHidden: CGFloat = 0
    
    @objc public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, navigationBar.isInteractiveHidingEnabled else {
            return
        }
        isUserScrolling = true
        initialScrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        initialNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
    }

    @objc public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, navigationBar.isInteractiveHidingEnabled else {
            return
        }

        guard isUserScrolling || isScrollingToTop else {
            return
        }
        
        let animated = false

        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        let currentUnderBarViewPercentHidden = navigationBar.underBarViewPercentHidden
        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        
        var navigationBarPercentHidden = currentNavigationBarPercentHidden
        var underBarViewPercentHidden = currentUnderBarViewPercentHidden
        var extendedViewPercentHidden = currentExtendedViewPercentHidden

        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        
        let barHeight = navigationBar.bar.frame.size.height
        let underBarViewHeight = navigationBar.underBarView.frame.size.height
        let extendedViewHeight = navigationBar.extendedView.frame.size.height

        let shouldHideUnderBarView = navigationBar.isUnderBarViewHidingEnabled && underBarViewHeight > 0
        let shouldHideExtendedView = navigationBar.isExtendedViewHidingEnabled && extendedViewHeight > 0

        if shouldHideUnderBarView {
            underBarViewPercentHidden = (scrollY/underBarViewHeight).wmf_normalizedPercentage
        }
        
        if shouldHideUnderBarView && shouldHideExtendedView {
            extendedViewPercentHidden = ((scrollY - underBarViewHeight)/extendedViewHeight).wmf_normalizedPercentage
        } else if shouldHideExtendedView {
            extendedViewPercentHidden = (scrollY/extendedViewHeight).wmf_normalizedPercentage
        }
        
        if !navigationBar.isBarHidingEnabled {
            navigationBarPercentHidden = 0
        } else if initialScrollY < extendedViewHeight + barHeight + underBarViewHeight {
            navigationBarPercentHidden = ((scrollY - extendedViewHeight - underBarViewHeight)/barHeight).wmf_normalizedPercentage
        } else if scrollY <= extendedViewHeight + barHeight + underBarViewHeight {
            navigationBarPercentHidden = min(initialNavigationBarPercentHidden, ((scrollY - extendedViewHeight - underBarViewHeight)/barHeight).wmf_normalizedPercentage)
        } else if initialNavigationBarPercentHidden == 0 && initialScrollY > extendedViewHeight + barHeight + underBarViewHeight {
            navigationBarPercentHidden = ((scrollY - initialScrollY)/barHeight).wmf_normalizedPercentage
        }

        guard currentExtendedViewPercentHidden != extendedViewPercentHidden || currentNavigationBarPercentHidden !=  navigationBarPercentHidden || currentUnderBarViewPercentHidden != underBarViewPercentHidden else {
            return
        }
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    @objc public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let navigationBar = navigationBar, navigationBar.isInteractiveHidingEnabled else {
            return
        }
        
        let barHeight = navigationBar.bar.frame.size.height
        let underBarViewHeight = navigationBar.underBarView.frame.size.height
        let extendedViewHeight = navigationBar.extendedView.frame.size.height

        let top = 0 - scrollView.contentInset.top
        let targetOffsetY = targetContentOffset.pointee.y - top
        if targetOffsetY < extendedViewHeight + barHeight + underBarViewHeight {
            if targetOffsetY < 0.5 * (extendedViewHeight + underBarViewHeight) { // both visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top)
            } else if targetOffsetY < extendedViewHeight + underBarViewHeight + 0.5 * barHeight  { // only nav bar visible
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + underBarViewHeight)
            } else if targetOffsetY < extendedViewHeight + barHeight {
                targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + barHeight + underBarViewHeight)
            }
            return
        }
        
        if initialScrollY < extendedViewHeight + barHeight + underBarViewHeight && targetOffsetY > extendedViewHeight + barHeight + underBarViewHeight { // let it naturally hide
            return
        }

        isUserScrolling = false

        let animated = true

        let extendedViewPercentHidden = navigationBar.extendedViewPercentHidden
        let underBarViewPercentHidden = navigationBar.underBarViewPercentHidden
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        
        var navigationBarPercentHidden: CGFloat = currentNavigationBarPercentHidden
        
        if !navigationBar.isBarHidingEnabled {
            navigationBarPercentHidden = 0
        } else if velocity.y > 0 {
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

        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }

    @objc public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
    }

    @objc public func scrollViewWillScrollToTop(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar, navigationBar.isInteractiveHidingEnabled else {
            return
        }
        initialNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        initialScrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        isScrollingToTop = true
    }

    @objc public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isScrollingToTop = false
    }

    @objc public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollingToTop = false
    }
}
