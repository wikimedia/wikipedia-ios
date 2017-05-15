import UIKit

public class AlignedImageButton: UIButton {
    
    @IBInspectable open var margin: CGFloat = 8
    @IBInspectable open var imageIsRightAligned: Bool = false {
        didSet {
            var updatedSemanticContentAttribute: UISemanticContentAttribute
            if wmf_effectiveUserInterfaceLayoutDirection == .leftToRight && imageIsRightAligned {
                updatedSemanticContentAttribute = .forceRightToLeft
            } else if wmf_effectiveUserInterfaceLayoutDirection == .rightToLeft && !imageIsRightAligned {
                updatedSemanticContentAttribute = .forceLeftToRight
            } else if wmf_effectiveUserInterfaceLayoutDirection == .rightToLeft {
                updatedSemanticContentAttribute = .forceLeftToRight
            } else {
                updatedSemanticContentAttribute = .forceRightToLeft
            }
            semanticContentAttribute = updatedSemanticContentAttribute
            titleLabel?.semanticContentAttribute = updatedSemanticContentAttribute
            imageView?.semanticContentAttribute = updatedSemanticContentAttribute

            adjustInsets()
        }
    }
    
    fileprivate func adjustInsets() {
        let inset = wmf_isRightToLeft ? -0.5 * margin : 0.5 * margin
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: abs(inset), bottom: 0, right: abs(inset))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustInsets()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        adjustInsets()
    }
    
}
