import UIKit

// CollectionViewCell is the base class of collection view cells that use manual layout.
// These cells use a manual layout rather than auto layout for a few reasons:
// 1. A significant in-code implementation was required anyway for handling the complexity of
//    hiding & showing different parts of the cells with auto layout
// 2. The performance advantage over auto layout for views that contain several article cells.
//    (To further alleviate this performance issue, ColumnarCollectionViewLayout could be updated
//     to not require a full layout pass for calculating the total collection view content size. Instead,
//     it could do a rough estimate pass, and then update the content size as the user scrolls.)
// 3. Handling RTL content on LTR devices and vice versa

open class CollectionViewCell: UICollectionViewCell {
    // MARK: - Methods for subclassing
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    open func setup() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        preservesSuperviewLayoutMargins = false
        contentView.preservesSuperviewLayoutMargins = false
        insetsLayoutMarginsFromSafeArea = false
        contentView.insetsLayoutMarginsFromSafeArea = false
        autoresizesSubviews = false
        contentView.autoresizesSubviews = false
        backgroundView = UIView()
        selectedBackgroundView = UIView()
        reset()
        setNeedsLayout()
    }
    
    open func reset() {
        
    }
    
    public var labelBackgroundColor: UIColor? {
        didSet {
            updateBackgroundColorOfLabels()
        }
    }

    public func setBackgroundColors(_ deselected: UIColor, selected: UIColor) {
        backgroundView?.backgroundColor = deselected
        selectedBackgroundView?.backgroundColor = selected
        let newColor = isSelectedOrHighlighted ? selected : deselected
        if newColor != labelBackgroundColor {
            labelBackgroundColor = newColor
        }
    }

    // Subclassers should call super
    open func updateBackgroundColorOfLabels() {
        
    }

    var isSelectedOrHighlighted: Bool = false
    
    public func updateSelectedOrHighlighted() {
        let newIsSelectedOrHighlighted = isSelected || isHighlighted
        guard newIsSelectedOrHighlighted != isSelectedOrHighlighted else {
            return
        }

        isSelectedOrHighlighted = newIsSelectedOrHighlighted

        // It appears that background color changes aren't properly animated when set within the animation block around isHighlighted/isSelected state changes
        // https://phabricator.wikimedia.org/T174341

        // To work around this, first set the background to clear without animation so that it stays clear throughought the animation
        UIView.performWithoutAnimation {
            self.labelBackgroundColor = .clear
        }

        // Then update the completion block to set the actual opaque color we want after the animation completes
        let existingCompletionBlock = CATransaction.completionBlock()
        CATransaction.setCompletionBlock {
            if let block = existingCompletionBlock {
                block()
            }
            self.labelBackgroundColor =  self.isSelected || self.isHighlighted ? self.selectedBackgroundView?.backgroundColor : self.backgroundView?.backgroundColor
        }
    }

    open override var isHighlighted: Bool {
        didSet {
            updateSelectedOrHighlighted()
        }
    }
    
    open override var isSelected: Bool {
        didSet {
            updateSelectedOrHighlighted()
        }
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

    open override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        setNeedsLayout()
    }

    final override public func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        backgroundView?.frame = bounds
        selectedBackgroundView?.frame = bounds
        let size = bounds.size
        _ = sizeThatFits(size, apply: true)
        updateAccessibilityElements()
        #if DEBUG
            for view in subviews {
                guard view !== backgroundView, view !== selectedBackgroundView else {
                    continue
                }
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
    
    open override func setNeedsLayout() {
        maybeUpdateFonts(with: traitCollection)
        super.setNeedsLayout()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
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
    
    // MARK: - Layout Margins
    
    public var layoutMarginsAdditions: UIEdgeInsets = .zero
    public var layoutMarginsInteractiveAdditions: UIEdgeInsets = .zero
    public func layoutWidth(for size: CGSize) -> CGFloat { // layoutWidth doesn't take into account interactive additions
        return size.width - layoutMargins.left - layoutMargins.right - layoutMarginsAdditions.right - layoutMarginsAdditions.left
    }
    public var calculatedLayoutMargins: UIEdgeInsets {
        let margins = self.layoutMargins
        return UIEdgeInsets(top:    margins.top     + layoutMarginsAdditions.top    + layoutMarginsInteractiveAdditions.top,
                            left:   margins.left    + layoutMarginsAdditions.left   + layoutMarginsInteractiveAdditions.left,
                            bottom: margins.bottom  + layoutMarginsAdditions.bottom + layoutMarginsInteractiveAdditions.bottom,
                            right:  margins.right   + layoutMarginsAdditions.right  + layoutMarginsInteractiveAdditions.right)
    }

}
