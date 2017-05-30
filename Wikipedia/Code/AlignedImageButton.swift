import UIKit

public class AlignedImageButton: UIButton {
    
    @IBInspectable open var margin: CGFloat = 8
    @IBInspectable open var imageIsRightAligned: Bool = false {
        didSet {
            updateSemanticContentAttribute()
            adjustInsets()
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateSemanticContentAttribute()
        adjustInsets()
    }
    
    fileprivate func updateSemanticContentAttribute() {
        let direction = UIView.userInterfaceLayoutDirection(for: .unspecified)
        if imageIsRightAligned {
            if direction == .leftToRight {
                semanticContentAttribute = .forceRightToLeft
            } else {
                semanticContentAttribute = .forceLeftToRight
            }
        } else {
            if direction == .leftToRight {
                semanticContentAttribute = .forceLeftToRight
            } else {
                semanticContentAttribute = .forceRightToLeft
            }
        }
    }

    fileprivate func adjustInsets() {
        let inset = semanticContentAttribute == .forceRightToLeft ? -0.5 * margin : 0.5 * margin
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: abs(inset), bottom: 0, right: abs(inset))
    }
    
}
