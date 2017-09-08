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
open class CollectionViewCell: UICollectionViewCell, Swipeable {
    // MARK - Methods for subclassing
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    open func setup() {
        backgroundView = UIView()
        selectedBackgroundView = UIView()
        reset()
        addPrivateContentView(to: super.contentView)
        setupActionsView(for: self)
        layoutSubviews()
    }
    
    open func reset() {
        // SWIPE: Make sure calling reset() in setup() is ok.
        resetSwipeable()
    }
    
    var labelBackgroundColor: UIColor? {
        didSet {
            updateBackgroundColorOfLabels()
        }
    }

    // Subclassers should call super
    open func updateBackgroundColorOfLabels() {
        
    }

    public final func updateSelectedOrHighlighted() {
        // It appears that background color changes aren't properly animated when set within the animation block around isHighlighted/isSelected state changes
        // https://phabricator.wikimedia.org/T174341

        // To work around this, first set the background to clear without animation so that it stays clear throughought the animation
        UIView.performWithoutAnimation {
            self.labelBackgroundColor = .clear
        }

        //Then update the completion block to set the actual opaque color we want after the animation completes
        let existingCompletionBlock = CATransaction.completionBlock()
        CATransaction.setCompletionBlock {
            if let block = existingCompletionBlock {
                block()
            }
            self.labelBackgroundColor = self.isSelected || self.isHighlighted ? self.selectedBackgroundView?.backgroundColor : self.backgroundView?.backgroundColor
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
    
    // MARK - Cell lifecycle
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    // MARK - Layout
    
    final override public func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        let _ = sizeThatFits(size, apply: true)
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
        if let attributesToFit = layoutAttributes as? WMFCVLAttributes, attributesToFit.precalculated {
            return attributesToFit
        }
        
        var sizeToFit = layoutAttributes.size
        sizeToFit.height = UIViewNoIntrinsicMetric
        var fitSize = self.sizeThatFits(sizeToFit)
        if fitSize == sizeToFit {
            return layoutAttributes
        } else  if let attributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes {
            fitSize.width = sizeToFit.width
            if fitSize.height == CGFloat.greatestFiniteMagnitude || fitSize.height == UIViewNoIntrinsicMetric {
                fitSize.height = layoutAttributes.size.height
            }
            attributes.frame = CGRect(origin: layoutAttributes.frame.origin, size: fitSize)
            return attributes
        } else {
            return layoutAttributes
        }
    }
    
    // MARK - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    open override func setNeedsLayout() {
        maybeUpdateFonts(with: traitCollection)
        super.setNeedsLayout()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        maybeUpdateFonts(with: traitCollection)
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.wmf_preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    // Override this method and call super
    open func updateFonts(with traitCollection: UITraitCollection) {
        
    }
    
    // MARK: - Swipeable
    
    var actionsView: CollectionViewCellActionsView?
    var privateContentView: UIView?
    var swipeType: CollectionViewCellSwipeType = .none
    var swipeInitialFramePosition: CGFloat = 0
    var swipeStartPosition: CGPoint = .zero
    var swipePastBounds: Bool = false
    var deletePending: Bool = false
    var swipeVelocity: CGFloat = 0
    var originalStartPosition: CGPoint = .zero
    
    var swipeTranslation: CGFloat {
        get {
            let x = privateContentView?.frame.origin.x ?? 0
            return x
        }
        set {
            privateContentView?.frame.origin.x = newValue
        }
    }
    
    var minimumSwipeTrackingPosition: CGFloat {
        guard let actionsView = actionsView else { return 0 }
        return -actionsView.maxActionWidth
    }
    
    var actions: [CollectionViewCellAction] {
        get {
            return self.actionsView?.actions ?? []
        }
        set {
            self.actionsView?.actions = newValue
        }
    }
    
    func setupActionsView(for cell: CollectionViewCell) {
        actionsView = CollectionViewCellActionsView(frame: CGRect.zero, cell: self)
    }
    
    func addPrivateContentView(to contentView: UIView) {
        // SWIPE: Should this be a separate method?
        privateContentView = UIView(frame: contentView.bounds)
        if let privateContentView = privateContentView {
        contentView.addSubview(privateContentView)
        }
    }
    
    func beginSwipe(with position: CGPoint, velocity: CGFloat) {
        guard let contentView = privateContentView else { return }
        
        swipeInitialFramePosition = contentView.frame.origin.x
        swipeStartPosition = position
        swipePastBounds = false
        
        showActionsView(with: swipeType)
        layoutSubviews()
        UIView.performWithoutAnimation {
            updateSwipe(with: position, velocity: velocity)
        }
    }
    
    func updateSwipe(with touchPosition: CGPoint, velocity: CGFloat) {
//        guard let privateContentView = privateContentView else { return }
//
//        let frame = privateContentView.frame
//        let width = frame.width
//        let totalTranslation = touchPosition.x - swipeStartPosition.x
//
//        let layoutMargins = self.layoutMargins
//        let leftMargin = layoutMargins.left
//
//        let origin = swipePastBounds ? leftMargin - width : swipeInitialFramePosition
//        var newTranslation = origin + totalTranslation
//
//        if swipeType == .primary {
//            let translatedRight = width + newTranslation
//            let leftBuffer = leftMargin
//            let breakPoint = abs(minimumSwipeTrackingPosition) + leftMargin
//
//            if velocity < 0 {
//                newTranslation = totalTranslation * (1 + log10(translatedRight/breakPoint))
//                if translatedRight < breakPoint || touchPosition.x < leftBuffer {
//                    swipePastBounds = true
//                    originalStartPosition = swipeStartPosition
//                    swipeStartPosition = touchPosition
//                    newTranslation = leftMargin - width
//                }
//            }
//        }
        
    }
    
    func showActionsView(with swipeType: CollectionViewCellSwipeType) {
        // We don't need to do this if the view is already visible.
        guard let actionsView = actionsView, actionsView.superview == nil else { return }
        
        let contentView = super.contentView
        
        // SWIPE: Style the cell with Theme.
        actionsView.backgroundColor = swipeType == .primary ? UIColor.red : UIColor.blue
        
        // SWIPE: When setting a swipeType, create appropriate subviews.
        actionsView.swipeType = swipeType
        print("self.swipeType: \(swipeType)")
        print("actionsView.swipeType: \(actionsView.swipeType)")
        contentView.addSubview(actionsView)
    }
    
    // MARK: Opening & closing action pane
    
    func openActionPane(animated: Bool) {
        guard let actionsView = actionsView else { return }
        
        let swipeType = actionsView.swipeType
        
        showActionsView(with: swipeType)
        setNeedsLayout()
        layoutIfNeeded()
        
        privateContentView?.isUserInteractionEnabled = false
        actionsView.isUserInteractionEnabled = true
        
        let targetTranslation = swipeType == .primary ? minimumSwipeTrackingPosition : -minimumSwipeTrackingPosition
        
        if animated {
            let totalDistance = swipeTranslation - targetTranslation
            let duration: CGFloat = 0.25
            // SWIPE: Figure out where to set swipeVelocity.
            let springVelocity = abs(swipeVelocity) * duration / totalDistance
            
            UIView.animate(withDuration: TimeInterval(duration), delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: springVelocity, options: .beginFromCurrentState, animations: {
                self.swipeTranslation = targetTranslation
                self.layoutIfNeeded()
            }, completion: nil)
        } // SWIPE: Handle else if animated is ever false.
        
    }
    
    // MARK: Prepare for reuse
    
    func resetSwipeable() {
        deletePending = false
        swipePastBounds = false
        swipeTranslation = 0
    }

}
