import UIKit

class RightAlignedImageButton: UIButton {
    
    let imageSpacing: CGFloat = 3
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var titleRect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        switch effectiveUserInterfaceLayoutDirection {
        case .rightToLeft:
            titleRect.origin.x = imageRect.maxX - titleRect.size.width + imageSpacing
        default:
            titleRect.origin.x = imageRect.minX - imageSpacing
        }
        return titleRect
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var imageRect = super.imageRect(forContentRect: contentRect)
        let titleRect = super.titleRect(forContentRect: contentRect)
        switch effectiveUserInterfaceLayoutDirection {
        case .rightToLeft:
            imageRect.origin.x = titleRect.minX - imageSpacing
        default:
            imageRect.origin.x = titleRect.maxX - imageRect.size.width + imageSpacing
        }
        return imageRect
    }
    
    override var effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        get {
            if #available(iOS 10.0, *) {
                return super.effectiveUserInterfaceLayoutDirection
            } else {
                return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
            }
        }
    }
}
