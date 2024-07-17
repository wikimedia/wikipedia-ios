import UIKit

// This is largely identical to CollectionViewCell. They both could be refactored to be
// wrappers around a SizeThatFitsView that determines cell & header/footer size.

class SizeThatFitsReusableView: UICollectionReusableView {

    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    open func setup() {
        preservesSuperviewLayoutMargins = false
        insetsLayoutMarginsFromSafeArea = false
        autoresizesSubviews = false
        updateFonts(with: traitCollection)
        reset()
        setNeedsLayout()
    }
    
    open func reset() {
        
    }
    
    // Subclassers should call super
    open func updateBackgroundColorOfLabels() {
        
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
    
    // MARK: - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: - Cell lifecycle
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    // MARK: - Layout
    
    final override public func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        _ = sizeThatFits(size, apply: true)
        updateAccessibilityElements()
        #if DEBUG
            for view in subviews {
                assert(view.autoresizingMask == [])
                assert(view.constraints == [])
            }
        #endif
    }
    
    final override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, apply: false)
    }
    
    final override public func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        if let attributesToFit = layoutAttributes as? ColumnarCollectionViewLayoutAttributes {
            layoutMargins = attributesToFit.layoutMargins
            if attributesToFit.precalculated {
                return attributesToFit
            }
        }
        
        var sizeToFit = layoutAttributes.size
        sizeToFit.height = UIView.noIntrinsicMetric
        var fitSize = self.sizeThatFits(sizeToFit)
        if fitSize == sizeToFit {
            return layoutAttributes
        } else  if let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes {
            fitSize.width = sizeToFit.width
            if fitSize.height == CGFloat.greatestFiniteMagnitude || fitSize.height == UIView.noIntrinsicMetric {
                fitSize.height = layoutAttributes.size.height
            }
            attributes.frame = CGRect(origin: layoutAttributes.frame.origin, size: fitSize)
            return attributes
        } else {
            return layoutAttributes
        }
    }
    
    // MARK: - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        maybeUpdateFonts(with: traitCollection)
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    // Override this method and call super
    open func updateFonts(with traitCollection: UITraitCollection) {
        
    }
}
