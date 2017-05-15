import UIKit

// CollectionViewCell is the base class of collection view cells that use manual layout.
// These cells use a manual layout rather than auto layout for a few reasons:
// 1. A significant in-code implementation was required anyway for handling the complexity of
//    hiding & showing different parts of the cells with auto layout
// 2. The performance advantage over auto layout for views that contain several article cells.
//    (To further alleviate this performance issue, WMFColumnarCollectionViewLayout could be updated
//     to not require a full layout pass for calculating the total collection view content size. Instead,
//     it could do a rough estimate pass, and then update the content size as the user scrolls.)

@objc(WMFCollectionViewCell)
open class CollectionViewCell: UICollectionViewCell {
    // MARK - Methods for subclassing
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    open func setup() {
        layoutSubviews()
    }
    
    // Subclassers should override sizeThatFits:apply: instead of layoutSubviews to lay out subviews.
    // In this method, subclassers should calculate the appropriate layout size and if apply is `true`, 
    // apply the layout to the subviews.
    open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        return size
    }
    
    // Subclassers should override updateAccessibilityElements to update any accessibility elements 
    // that should be updated after layout. Subclassers must call super.updateAccessibilityElements()
    open func updateAccessibilityElements() {
        
    }
    
    // MARK - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK - Layout
    
    final override public func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        let _ = sizeThatFits(size, apply: true)
        updateAccessibilityElements()
    }
    
    final override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, apply: false)
    }
    
    final override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if let attributesToFit = layoutAttributes as? WMFCVLAttributes, attributesToFit.precalculated {
            return attributesToFit
        }
        
        var sizeToFit = layoutAttributes.size
        sizeToFit.height = CGFloat.greatestFiniteMagnitude
        var fitSize = self.sizeThatFits(sizeToFit)
        if fitSize == sizeToFit {
            return layoutAttributes
        } else  if let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes {
            fitSize.width = sizeToFit.width
            if fitSize.height == CGFloat.greatestFiniteMagnitude {
                fitSize.height = layoutAttributes.size.height
            }
            attributes.frame = CGRect(origin: layoutAttributes.frame.origin, size: fitSize)
            return attributes
        } else {
            return layoutAttributes
        }
    }
}
