import UIKit

@objc(WMFAlignedImageButton)
public class AlignedImageButton: UIButton {

    /// Spacing between the image and title
    @IBInspectable open var horizontalSpacing: CGFloat = 8 {
        didSet {
            adjustInsets()
        }
    }

    /// Padding added to the top and bottom of the button
    @IBInspectable open var verticalPadding: CGFloat = 0 {
        didSet {
            adjustInsets()
        }
    }
    
    @IBInspectable open var leftPadding: CGFloat = 0 {
        didSet {
            adjustInsets()
        }
    }
    
    @IBInspectable open var rightPadding: CGFloat = 0 {
        didSet {
            adjustInsets()
        }
    }

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
                imageView?.semanticContentAttribute = .forceLeftToRight
            } else {
                semanticContentAttribute = .forceLeftToRight
                imageView?.semanticContentAttribute = .forceRightToLeft
            }
        } else {
            if direction == .leftToRight {
                semanticContentAttribute = .forceLeftToRight
                imageView?.semanticContentAttribute = .forceLeftToRight
            } else {
                semanticContentAttribute = .forceRightToLeft
                imageView?.semanticContentAttribute = .forceRightToLeft
            }
        }
    }
    
    fileprivate func adjustInsets() {
        let inset = semanticContentAttribute == .forceRightToLeft ? -0.5 * horizontalSpacing : 0.5 * horizontalSpacing
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
        contentEdgeInsets = UIEdgeInsets(top: verticalPadding, left: abs(inset) + leftPadding, bottom: verticalPadding, right: abs(inset) + rightPadding)
    }
    
}
