import UIKit

@objc(WMFAlignedImageButton)
public class AlignedImageButton: UIButton {
    private var isFirstLayout = true

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isFirstLayout {
            updateSemanticContentAttribute()
            adjustInsets()
            isFirstLayout = false
        }
    }

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
        let newLayoutDirection: UIUserInterfaceLayoutDirection = traitCollection.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        guard newLayoutDirection != layoutDirection else {
            return
        }
        updateSemanticContentAttribute()
        adjustInsets()
    }

    public override func wmf_sizeThatFits(_ maximumSize: CGSize) -> CGSize {
        // When iOS's Bold Text setting was turned on, labels on Explore feed buttons were moving to two lines,
        // presumably due to rounding errors in this function. The extra 1 here allows them to layout as expected.
        // The buttons having problems were AlignedImageButtons and SaveButtons (which are subclasses of AlignedImageButtons).
        // (Details: The button image's width is calculated as 12, however on screen the image takes a width of 13.)
        let defaultSize = super.wmf_sizeThatFits(maximumSize)

        guard let _ = self.image(for: .normal) else {
            // If image, it should layout fine.
            return defaultSize
        }
        return CGSize(width: defaultSize.width + 1, height: defaultSize.height)
    }
    
    var layoutDirection: UIUserInterfaceLayoutDirection = .leftToRight
    fileprivate func updateSemanticContentAttribute() {
        layoutDirection = traitCollection.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        if imageIsRightAligned {
            if layoutDirection == .leftToRight {
                semanticContentAttribute = .forceRightToLeft
                imageView?.semanticContentAttribute = .forceLeftToRight
            } else {
                semanticContentAttribute = .forceLeftToRight
                imageView?.semanticContentAttribute = .forceRightToLeft
            }
        } else {
            if layoutDirection == .leftToRight {
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
        titleEdgeInsets = UIEdgeInsets(top: verticalPadding, left: inset, bottom: verticalPadding, right: -inset)
        contentEdgeInsets = UIEdgeInsets(top: verticalPadding, left: abs(inset) + leftPadding, bottom: verticalPadding, right: abs(inset) + rightPadding)
    }
    
}
