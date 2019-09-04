import UIKit

// SizeThatFitsView is the base class of views that use manual layout.
// These views use a manual layout rather than auto layout for convienence within a CollectionViewCell

@objc(WMFSizeThatFitsView)
open class SizeThatFitsView: SetupView {

    // MARK - Methods for subclassing
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    override open func setup() {
        super.setup()
        translatesAutoresizingMaskIntoConstraints = false
        autoresizesSubviews = false
        updateFonts(with: traitCollection)
        setNeedsLayout()
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
    
    // MARK - Layout
    
    final override public func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        let _ = sizeThatFits(size, apply: true)
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

    open func updateFonts(with traitCollection: UITraitCollection) {

    }
}
