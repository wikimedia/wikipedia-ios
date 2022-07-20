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
        // Rounded: Sometimes when we expect them to be equal, these are less than .2 different (due to rounding in earleir calculation) - and with multiple layout passes, it caused a large scrolling bug on a VC's launch.
        return contentOffset.y.rounded(.up) <= topOffsetY.rounded(.up)
    }

    private var isAtBottom: Bool {
        // Rounded: Sometimes when we expect them to be equal, these are less than .2 different (due to rounding in earleir calculation) - and with multiple layout passes, it caused a large scrolling bug on a VC's launch.
        return contentOffset.y.rounded(.up) >= bottomOffsetY.rounded(.up)
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

    @objc(wmf_setContentInset:verticalScrollIndicatorInsets:preserveContentOffset:preserveAnimation:)
    public func setContentInset(_ updatedContentInset: UIEdgeInsets, verticalScrollIndicatorInsets updatedVerticalScrollIndicatorInsets: UIEdgeInsets, preserveContentOffset: Bool = true, preserveAnimation: Bool = false) -> Bool {
        guard updatedContentInset != contentInset || updatedVerticalScrollIndicatorInsets != verticalScrollIndicatorInsets else {
            return false
        }
        let wasAtTop = isAtTop
        let wasAtBottom = isAtBottom
        verticalScrollIndicatorInsets = updatedVerticalScrollIndicatorInsets

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
