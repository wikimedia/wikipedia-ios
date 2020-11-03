import UIKit

extension UIScrollView {
    private var topOffsetY: CGFloat {
        return 0 - adjustedContentInset.top
    }

    public var bottomOffsetY: CGFloat {
        return contentSize.height - bounds.size.height + adjustedContentInset.bottom
    }

    private var topOffset: CGPoint {
        return CGPoint(x: contentOffset.x, y: topOffsetY)
    }

    private var bottomOffset: CGPoint {
        return CGPoint(x: contentOffset.x, y: bottomOffsetY)
    }

    public var isAtTop: Bool {
        /// 0.5 is to account for  rounding errors. Sometimes when we expect them to be equal, these are less than .2 different (due to rounding) - and with multiple layout passes, it caused a large scrolling bug on a VC's launch.
        return contentOffset.y <= topOffsetY + 0.5
    }

    private var isAtBottom: Bool {
        /// 0.5 is to account for  rounding errors. Sometimes when we expect them to be equal, these are less than .2 different (due to rounding) - and with multiple layout passes, it caused a large scrolling bug on a VC's launch.
        return contentOffset.y >= bottomOffsetY - 0.5
    }
    
    public var verticalOffsetPercentage: CGFloat {
        get {
            let height = contentSize.height
            guard height > 0 else {
                return 0
            }
            return contentOffset.y / height
        }
        set {
            let newOffsetY = contentSize.height * newValue
            setContentOffset(CGPoint(x: contentOffset.x, y: newOffsetY), animated: false)
        }
    }

    @objc(wmf_setContentInset:scrollIndicatorInsets:preserveContentOffset:preserveAnimation:)
    public func setContentInset(_ updatedContentInset: UIEdgeInsets, scrollIndicatorInsets updatedScrollIndicatorInsets: UIEdgeInsets, preserveContentOffset: Bool = true, preserveAnimation: Bool = false) -> Bool {
        guard updatedContentInset != contentInset || updatedScrollIndicatorInsets != scrollIndicatorInsets else {
            return false
        }
        let wasAtTop = isAtTop
        let wasAtBottom = isAtBottom
        scrollIndicatorInsets = updatedScrollIndicatorInsets

        if preserveAnimation {
            contentInset = updatedContentInset
        } else {
            let wereAnimationsEnabled = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            contentInset = updatedContentInset
            UIView.setAnimationsEnabled(wereAnimationsEnabled)
        }
        
        guard preserveContentOffset else {
            return true
        }
        
        if wasAtTop {
            contentOffset = topOffset
        } else if contentSize.height > bounds.inset(by: adjustedContentInset).height && wasAtBottom {
            contentOffset = bottomOffset
        }
        
        return true
    }
}
