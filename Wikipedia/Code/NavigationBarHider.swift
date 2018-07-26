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
        guard let navigationBar = navigationBar else {
            return
        }
        
        guard scrollView.contentSize.height > 0 else {
            navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 0, animated: false)
            if navigationBar.isShadowHidingEnabled {
                navigationBar.shadowAlpha = 0
            } else {
                navigationBar.shadowAlpha = 1
            }
            return
        }

        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        var adjustedScrollY = scrollY
        let barTopSpacing = navigationBar.barTopSpacing
        let barHeight = navigationBar.barHeight
        let underBarViewHeight = navigationBar.underBarViewHeight
        let extendedViewHeight = navigationBar.extendedViewHeight

        var totalHideableHeight: CGFloat = barTopSpacing
        
        if navigationBar.isBarHidingEnabled {
            totalHideableHeight += barHeight
        }
        
        if navigationBar.isUnderBarViewHidingEnabled {
            totalHideableHeight += underBarViewHeight
        }
        
        if navigationBar.isExtendedViewHidingEnabled {
            totalHideableHeight += extendedViewHeight
        }
        
        if navigationBar.isShadowHidingEnabled {
            if totalHideableHeight > 0 {
                navigationBar.shadowAlpha = (scrollY/totalHideableHeight).wmf_normalizedPercentage
            } else {
                navigationBar.shadowAlpha = (scrollY/max(barHeight, 32)).wmf_normalizedPercentage
            }
        }

        guard navigationBar.isInteractiveHidingEnabled, isUserScrolling || isScrollingToTop || scrollY < totalHideableHeight else {
            return
        }
        
        let animated = false
        
        let currentTopSpacingPercentHidden = navigationBar.topSpacingPercentHidden
        let currentNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
        let currentUnderBarViewPercentHidden = navigationBar.underBarViewPercentHidden
        let currentExtendedViewPercentHidden = navigationBar.extendedViewPercentHidden

        var navigationBarPercentHidden = currentNavigationBarPercentHidden
        var underBarViewPercentHidden = currentUnderBarViewPercentHidden
        var extendedViewPercentHidden = currentExtendedViewPercentHidden
        
        let shouldHideUnderBarView = navigationBar.isUnderBarViewHidingEnabled && underBarViewHeight > 0
        let shouldHideExtendedView = navigationBar.isExtendedViewHidingEnabled && extendedViewHeight > 0
        
        if shouldHideUnderBarView {
            if navigationBar.shouldTransformUnderBarViewWithBar {
                if !navigationBar.isBarHidingEnabled {
                    underBarViewPercentHidden = 0
                } else if initialScrollY < totalHideableHeight {
                    underBarViewPercentHidden = (adjustedScrollY/underBarViewHeight).wmf_normalizedPercentage
                } else if scrollY <= totalHideableHeight {
                    underBarViewPercentHidden = min(initialNavigationBarPercentHidden, (scrollY/underBarViewHeight).wmf_normalizedPercentage)
                } else if initialNavigationBarPercentHidden == 0 && initialScrollY > extendedViewHeight + barHeight + underBarViewHeight {
                    underBarViewPercentHidden = ((adjustedScrollY - initialScrollY)/underBarViewHeight).wmf_normalizedPercentage
                }
            } else {
                underBarViewPercentHidden = (adjustedScrollY/underBarViewHeight).wmf_normalizedPercentage
            }
            adjustedScrollY -= underBarViewHeight
        }
        
        if shouldHideExtendedView {
            extendedViewPercentHidden = (adjustedScrollY/extendedViewHeight).wmf_normalizedPercentage
            adjustedScrollY -= extendedViewHeight
        }

        let topSpacingPercentHidden = barTopSpacing > 0 ? (adjustedScrollY/barTopSpacing).wmf_normalizedPercentage : 1

        if !navigationBar.isBarHidingEnabled {
            navigationBarPercentHidden = 0
        } else if initialScrollY < totalHideableHeight {
            navigationBarPercentHidden = (adjustedScrollY/barHeight).wmf_normalizedPercentage
        } else if scrollY <= totalHideableHeight {
            navigationBarPercentHidden = min(initialNavigationBarPercentHidden, (adjustedScrollY/barHeight).wmf_normalizedPercentage)
        } else if initialNavigationBarPercentHidden == 0 && initialScrollY > totalHideableHeight {
            if navigationBar.shouldTransformUnderBarViewWithBar {
                navigationBarPercentHidden = ((scrollY - initialScrollY - underBarViewHeight)/barHeight).wmf_normalizedPercentage
            } else {
                navigationBarPercentHidden = ((scrollY - initialScrollY)/barHeight).wmf_normalizedPercentage
            }
        }

        guard currentExtendedViewPercentHidden != extendedViewPercentHidden || currentNavigationBarPercentHidden !=  navigationBarPercentHidden || currentUnderBarViewPercentHidden != underBarViewPercentHidden || currentTopSpacingPercentHidden != topSpacingPercentHidden else {
            return
        }
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, topSpacingPercentHidden: topSpacingPercentHidden, animated: animated, additionalAnimations:{
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }
    
    @objc public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let navigationBar = navigationBar, navigationBar.isInteractiveHidingEnabled else {
            return
        }
        
        let barHeight = navigationBar.barHeight
        let underBarViewHeight = navigationBar.underBarViewHeight
        let extendedViewHeight = navigationBar.extendedViewHeight
        let top = 0 - scrollView.contentInset.top
        let targetOffsetY = targetContentOffset.pointee.y - top
        if targetOffsetY < extendedViewHeight + barHeight + underBarViewHeight {
            if navigationBar.shouldTransformUnderBarViewWithBar { // transform whole bar together
                if targetOffsetY < 0.5 * (extendedViewHeight + underBarViewHeight + barHeight) {
                    targetContentOffset.pointee = CGPoint(x: 0, y: top)
                } else {
                    targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + barHeight + underBarViewHeight)
                }
            } else {
                if targetOffsetY < 0.5 * (extendedViewHeight + underBarViewHeight) { // both visible
                    targetContentOffset.pointee = CGPoint(x: 0, y: top)
                } else if targetOffsetY < extendedViewHeight + underBarViewHeight + 0.5 * barHeight  { // only nav bar visible
                    targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + underBarViewHeight)
                } else if targetOffsetY < extendedViewHeight + barHeight {
                    targetContentOffset.pointee = CGPoint(x: 0, y: top + extendedViewHeight + barHeight + underBarViewHeight)
                }
            }
            return
        }
        
        if initialScrollY < extendedViewHeight + barHeight + underBarViewHeight && targetOffsetY > extendedViewHeight + barHeight + underBarViewHeight { // let it naturally hide
            return
        }

        isUserScrolling = false

        let animated = true

        let currentTopSpacingPercentHidden: CGFloat = navigationBar.topSpacingPercentHidden
        let extendedViewPercentHidden: CGFloat = navigationBar.extendedViewPercentHidden
        let currentUnderBarViewPercentHidden: CGFloat = navigationBar.underBarViewPercentHidden
        let currentNavigationBarPercentHidden: CGFloat = navigationBar.navigationBarPercentHidden
        
        var navigationBarPercentHidden: CGFloat = currentNavigationBarPercentHidden
        var underBarViewPercentHidden: CGFloat = currentUnderBarViewPercentHidden

        
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

        if navigationBar.shouldTransformUnderBarViewWithBar {
            underBarViewPercentHidden = navigationBarPercentHidden
        }

        guard navigationBarPercentHidden != currentNavigationBarPercentHidden || underBarViewPercentHidden != currentUnderBarViewPercentHidden else {
            return
        }

        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, topSpacingPercentHidden: currentTopSpacingPercentHidden, animated: animated, additionalAnimations:{
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
