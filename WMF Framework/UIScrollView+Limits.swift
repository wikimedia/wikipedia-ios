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

    @objc public func wmf_setContentInset(_ updatedContentInset: UIEdgeInsets, scrollIndicatorInsets updatedScrollIndicatorInsets: UIEdgeInsets, preserveContentOffset: Bool = true) -> Bool {
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
        
        guard preserveContentOffset else {
            return true
        }
        
        if wasAtTop {
            contentOffset = wmf_topOffset
        } else if contentSize.height > bounds.inset(by: contentInset).height && wasAtBottom {
            contentOffset = wmf_bottomOffset
        }
        
        return true
    }
}
