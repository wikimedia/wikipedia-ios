import UIKit

@objc(WMFNavigationBarHiderDelegate)
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

// This class works in concert w/ `NavigationBar` to implement our custom Navigation Bar.
// This `NavigationBar` class holds the properties and subviews, and `NavigationBarHider` implements the hiding logic when `isInteractiveHidingEnabled` is true.
@objc(WMFNavigationBarHider)
public class NavigationBarHider: NSObject {
    @objc public weak var navigationBar: NavigationBar?
    @objc public weak var delegate: NavigationBarHiderDelegate?
    
    fileprivate var isUserScrolling: Bool = false
    fileprivate var isScrollingToTop: Bool = false
    fileprivate var isProgramaticallyScrolling: Bool = false
    fileprivate var initialScrollY: CGFloat = 0
    fileprivate var initialNavigationBarPercentHidden: CGFloat = 0

    private func setDataForScroll(yOffset: CGFloat, topContentInset: CGFloat) {
        guard let navigationBar = navigationBar else {
            return
        }
        initialScrollY = yOffset + topContentInset
        initialNavigationBarPercentHidden = navigationBar.navigationBarPercentHidden
    }

    // This is used by OnThisDayViewController to fix a problem with the UnderbarView
    public func setIsProgramaticallyScrolling(_ isProgramaticallyScrolling: Bool, yOffset: CGFloat, topContentInset: CGFloat) {
        guard navigationBar?.isInteractiveHidingEnabled == true else {
            return
        }
        
        self.isProgramaticallyScrolling = isProgramaticallyScrolling

        if isProgramaticallyScrolling {
            setDataForScroll(yOffset: yOffset, topContentInset: topContentInset)
        }
    }
    
    @objc public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard navigationBar?.isInteractiveHidingEnabled == true else {
            return
        }
        isUserScrolling = true
        setDataForScroll(yOffset: scrollView.contentOffset.y, topContentInset: scrollView.contentInset.top)
    }

    // During the scroll, adjusts the amount of the navigation bar, under bar view, extended view, and top spacing is hidden. This is called frequently during scrolling.
    @objc public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let navigationBar = navigationBar else {
            return
        }

        if isProgramaticallyScrolling {
            // When programatically scrolling on a just-created scroll view, we need a layout pass to get accurate heights.
            scrollView.layoutIfNeeded()
            navigationBar.layoutIfNeeded()
        }

        guard scrollView.contentSize.height > 0 else {
            if navigationBar.isAdjustingHidingFromContentInsetChangesEnabled {
                navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 0, animated: false)
                if navigationBar.isShadowHidingEnabled {
                    navigationBar.shadowAlpha = 0
                } else {
                    navigationBar.shadowAlpha = 1
                }
            }
            return
        }

        let scrollY = scrollView.contentOffset.y + scrollView.contentInset.top
        var adjustedScrollY = scrollY
        let barTopSpacing = navigationBar.barTopSpacing
        let barHeight = navigationBar.barHeight
        let underBarViewHeight = navigationBar.underBarViewHeight
        let extendedViewHeight = navigationBar.extendedViewHeight

        let totalHideableHeight: CGFloat = navigationBar.hideableHeight
        
        if navigationBar.isShadowHidingEnabled {
            if totalHideableHeight > 0 {
                navigationBar.shadowAlpha = (scrollY/totalHideableHeight).wmf_normalizedPercentage
            } else {
                navigationBar.shadowAlpha = (scrollY/max(barHeight, 32)).wmf_normalizedPercentage
            }
        }

        guard navigationBar.isInteractiveHidingEnabled, isUserScrolling || isScrollingToTop || isProgramaticallyScrolling || scrollY < totalHideableHeight else {
            return
        }

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
        adjustedScrollY -= barTopSpacing
        
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

        let animated = false
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, topSpacingPercentHidden: topSpacingPercentHidden, animated: animated, additionalAnimations: {
            self.delegate?.navigationBarHider(self, didSetNavigationBarPercentHidden: navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, animated: animated)
        })
    }

    // After the scroll is complete, adjusts (w/ animation) the final hidden status of the navigation bar, under bar view, extended view, and top spacing.
    @objc public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard let navigationBar = navigationBar, navigationBar.isInteractiveHidingEnabled else {
            return
        }
        
        let topSpacingHideableHeight: CGFloat = navigationBar.topSpacingHideableHeight
        let barHideableHeight = navigationBar.barHideableHeight
        let underBarViewHideableHeight = navigationBar.underBarViewHideableHeight
        let extendedViewHideableHeight = navigationBar.extendedViewHideableHeight
        
        let totalHideableHeight: CGFloat = navigationBar.hideableHeight
        
        let top = 0 - scrollView.contentInset.top
        let targetOffsetY = targetContentOffset.pointee.y - top
        
        // the maximum amount targetOffsetY is expected to get considering bounds + content size & insets
        let maxTargetOffsetY = scrollView.contentSize.height - (scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom)

        if targetOffsetY < totalHideableHeight {
            if navigationBar.shouldTransformUnderBarViewWithBar { // transform whole bar together
                if targetOffsetY < 0.5 * totalHideableHeight {
                    targetContentOffset.pointee = CGPoint(x: 0, y: top)
                } else {
                    targetContentOffset.pointee = CGPoint(x: 0, y: top + totalHideableHeight)
                }
            } else {
                let targetContentOffsetX = CGFloat(targetContentOffset.pointee.x)
                
                if targetOffsetY < 0.5 * underBarViewHideableHeight && targetOffsetY < maxTargetOffsetY { // show everything if underbar view is less than half hidden and we are not at the bottom
                    targetContentOffset.pointee = CGPoint(x: targetContentOffsetX, y: top)
                } else if targetOffsetY < underBarViewHideableHeight + 0.5 * extendedViewHideableHeight { // just hide underbar view if it's more than half hidden and extended view is less than half hidden
                    targetContentOffset.pointee = CGPoint(x: targetContentOffsetX, y: top + underBarViewHideableHeight)
                } else if targetOffsetY < underBarViewHideableHeight + extendedViewHideableHeight + 0.5 * topSpacingHideableHeight { // hide extended & under bar views
                    targetContentOffset.pointee = CGPoint(x: targetContentOffsetX, y: top + underBarViewHideableHeight + extendedViewHideableHeight)
                } else if targetOffsetY < underBarViewHideableHeight + extendedViewHideableHeight + topSpacingHideableHeight + 0.5 * barHideableHeight { // hide top spacing
                    targetContentOffset.pointee = CGPoint(x: targetContentOffsetX, y: top + underBarViewHideableHeight + extendedViewHideableHeight + topSpacingHideableHeight)
                } else { // hide everything
                    targetContentOffset.pointee = CGPoint(x: targetContentOffsetX, y: top + totalHideableHeight)
                }
            }
            return
        }
        
        if initialScrollY < totalHideableHeight && targetOffsetY > totalHideableHeight { // let it naturally hide
            return
        }

        isUserScrolling = false

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

        let animated = true
        navigationBar.setNavigationBarPercentHidden(navigationBarPercentHidden, underBarViewPercentHidden: underBarViewPercentHidden, extendedViewPercentHidden: extendedViewPercentHidden, topSpacingPercentHidden: currentTopSpacingPercentHidden, animated: animated, additionalAnimations: {
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
        setDataForScroll(yOffset: scrollView.contentOffset.y, topContentInset: scrollView.contentInset.top)
        isScrollingToTop = true
    }

    @objc public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isScrollingToTop = false
    }

    @objc public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollingToTop = false
    }
}
