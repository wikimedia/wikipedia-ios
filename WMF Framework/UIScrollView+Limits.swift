import UIKit

extension UIScrollView {
    fileprivate var wmf_topOffsetY: CGFloat {
        return 0 - contentInset.top
    }

    fileprivate var wmf_bottomOffsetY: CGFloat {
        return contentSize.height - bounds.size.height + contentInset.bottom
    }

    fileprivate var wmf_topOffset: CGPoint {
        return CGPoint(x: contentOffset.x, y: wmf_topOffsetY)
    }

    fileprivate var wmf_bottomOffset: CGPoint {
        return CGPoint(x: contentOffset.x, y: wmf_bottomOffsetY)
    }

    public var wmf_isAtTop: Bool {
        return contentOffset.y <= wmf_topOffsetY
    }

    fileprivate var wmf_isAtBottom: Bool {
        return contentOffset.y >= wmf_bottomOffsetY
    }

    @objc public func wmf_setContentInsetPreservingTopAndBottomOffset(_ updatedContentInset: UIEdgeInsets, scrollIndicatorInsets updatedScrollIndicatorInsets: UIEdgeInsets, withNavigationBar navigationBar: NavigationBar?) -> Bool {
        guard updatedContentInset != contentInset || updatedScrollIndicatorInsets != scrollIndicatorInsets else {
            return false
        }
        let wasAtTop = wmf_isAtTop
        let wasAtBottom = wmf_isAtBottom
        scrollIndicatorInsets = updatedScrollIndicatorInsets
        
        let wereAnimationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        contentInset = updatedContentInset
        UIView.setAnimationsEnabled(wereAnimationsEnabled)
        
        if wasAtTop {
            contentOffset = wmf_topOffset
        } else if contentSize.height > UIEdgeInsetsInsetRect(bounds, contentInset).height && wasAtBottom {
            contentOffset = wmf_bottomOffset
        }

        if wmf_isAtTop, let nb = navigationBar, nb.isInteractiveHidingEnabled {
            nb.setPercentHidden(0, animated: false)
        }

        return true
    }
}
