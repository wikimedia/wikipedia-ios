import UIKit


class AlignedImageButton: UIButton {
    
    @IBInspectable open var margin: CGFloat = 8
    
    @IBInspectable open var imageIsRightAligned: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    private var isImageActuallyRightAligned: Bool {
        get {
            return effectiveUserInterfaceLayoutDirection == .rightToLeft ? !imageIsRightAligned : imageIsRightAligned
        }
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

    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var titleRect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        let totalImageWidth = margin + imageRect.width
        let availableWidth = contentRect.width - totalImageWidth - margin
        let centeredInAvailableWidth = round(0.5*availableWidth - 0.5*titleRect.width)
        if isImageActuallyRightAligned {
            titleRect.origin.x = centeredInAvailableWidth + margin
        } else {
            titleRect.origin.x = totalImageWidth + centeredInAvailableWidth
        }
        return titleRect
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var imageRect = super.imageRect(forContentRect: contentRect)
        if isImageActuallyRightAligned {
            imageRect.origin.x = contentRect.maxX - imageRect.size.width - margin
        } else {
            imageRect.origin.x = margin
        }
        return imageRect
    }
    
    }
