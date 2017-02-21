import UIKit

class RightAlignedImageButton: UIButton {
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var titleRect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        titleRect.origin.x = imageRect.origin.x
        return titleRect
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var imageRect = super.imageRect(forContentRect: contentRect)
        let titleRect = super.titleRect(forContentRect: contentRect)
        imageRect.origin.x = titleRect.origin.x + titleRect.size.width
        return imageRect
    }
}
