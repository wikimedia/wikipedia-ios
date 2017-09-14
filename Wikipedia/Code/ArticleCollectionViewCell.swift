import UIKit

@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: CollectionViewCell {
    static let defaultMargins = UIEdgeInsetsMake(15, 13, 15, 13)
    
    @objc public let titleLabel = UILabel()
    @objc public let descriptionLabel = UILabel()
    @objc public let imageView = UIImageView()
    @objc public let saveButton = SaveButton()
    @objc public var extractLabel: UILabel?
    
    private var kvoButtonTitleContext = 0
    
    open override func setup() {
        titleFontFamily = .georgia
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        if #available(iOSApplicationExtension 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        
        titleLabel.isOpaque = true
        descriptionLabel.isOpaque = true
        imageView.isOpaque = true
        saveButton.isOpaque = true
        
        actionsView = CollectionViewCellActionsView(frame: CGRect.zero, cell: self)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(saveButton)

        saveButton.saveButtonState = .longSave
        saveButton.addObserver(self, forKeyPath: "titleLabel.text", options: .new, context: &kvoButtonTitleContext)
        
        super.setup()
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        titleFontFamily = .georgia
        titleTextStyle = .title1
        descriptionFontFamily = .system
        descriptionTextStyle  = .subheadline
        extractFontFamily = .system
        extractTextStyle  = .subheadline
        saveButtonFontFamily = .systemMedium
        saveButtonTextStyle  = .subheadline
        margins = ArticleCollectionViewCell.defaultMargins
        spacing = 5
        imageViewDimension = 70
        saveButtonTopSpacing = 5
        imageView.wmf_reset()
        resetSwipeable()
        updateFonts(with: traitCollection)
    }

    override open func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        titleLabel.backgroundColor = labelBackgroundColor
        descriptionLabel.backgroundColor = labelBackgroundColor
        extractLabel?.backgroundColor = labelBackgroundColor
        saveButton.backgroundColor = labelBackgroundColor
        saveButton.titleLabel?.backgroundColor = labelBackgroundColor
    }
    
    deinit {
        saveButton.removeObserver(self, forKeyPath: "titleLabel.text", context: &kvoButtonTitleContext)
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        guard apply else {
            return super.sizeThatFits(size, apply: apply)
        }
        
        layoutActionsView()
        
        if let currentSnapshot = swipeSnapshotView, let actionsView = actionsView {
            currentSnapshot.removeFromSuperview()
            actionsView.removeFromSuperview()
            let newSnapshot = contentView.snapshotView(afterScreenUpdates: true) ?? UIView()
            newSnapshot.frame = contentView.bounds
            contentView.addSubview(newSnapshot)
            contentView.addSubview(actionsView)
            swipeSnapshotView = newSnapshot
        }
        
        return super.sizeThatFits(size, apply: apply)
    }
    
    func layoutActionsView() {
        let width = actionsView?.maximumWidth ?? 0
        actionsView?.frame = CGRect(x: contentView.bounds.width - width, y: 0, width: width, height: contentView.bounds.height)
        actionsView?.setNeedsLayout()
    }

    
    // MARK - View configuration
    // These properties can mutate with each use of the cell. They should be reset by the `reset` function. Call setsNeedLayout after adjusting any of these properties
    
    public var titleFontFamily: WMFFontFamily?
    public var titleTextStyle: UIFontTextStyle?
    
    public var descriptionFontFamily: WMFFontFamily?
    public var descriptionTextStyle: UIFontTextStyle?
    
    public var extractFontFamily: WMFFontFamily?
    public var extractTextStyle: UIFontTextStyle?
    
    public var saveButtonFontFamily: WMFFontFamily?
    public var saveButtonTextStyle: UIFontTextStyle?
    
    public var imageViewDimension: CGFloat! //used as height on full width cell, width & height on right aligned
    public var margins: UIEdgeInsets!
    public var spacing: CGFloat!
    public var saveButtonTopSpacing: CGFloat!
    
    @objc public var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    @objc public var isSaveButtonHidden = false {
        didSet {
            saveButton.isHidden = isSaveButtonHidden
            setNeedsLayout()
        }
    }

    open override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.setFont(with:titleFontFamily, style: titleTextStyle, traitCollection: traitCollection)
        descriptionLabel.setFont(with:descriptionFontFamily, style: descriptionTextStyle, traitCollection: traitCollection)
        extractLabel?.setFont(with:extractFontFamily, style: extractTextStyle, traitCollection: traitCollection)
        saveButton.titleLabel?.setFont(with:saveButtonFontFamily, style: saveButtonTextStyle, traitCollection: traitCollection)
    }
    
    // MARK - Semantic content
    
    open var articleSemanticContentAttribute: UISemanticContentAttribute = .unspecified {
        didSet {
            titleLabel.semanticContentAttribute = articleSemanticContentAttribute
            descriptionLabel.semanticContentAttribute = articleSemanticContentAttribute
            extractLabel?.semanticContentAttribute = articleSemanticContentAttribute
        }
    }
    
    // MARK - Accessibility
    
    open override func updateAccessibilityElements() {
        var updatedAccessibilityElements: [Any] = []
        var groupedLabels = [titleLabel, descriptionLabel]
        if let extract = extractLabel {
            groupedLabels.append(extract)
        }
        updatedAccessibilityElements.append(LabelGroupAccessibilityElement(view: self, labels: groupedLabels))
        
        if !isSaveButtonHidden {
            updatedAccessibilityElements.append(saveButton)
        }
        
        accessibilityElements = updatedAccessibilityElements
    }
    
    // MARK - KVO
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &kvoButtonTitleContext {
            setNeedsLayout()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: - Swipeable
    
    var collectionView: UICollectionView? {
        return self.superview as? UICollectionView
    }
    
    public var actionsView: CollectionViewCellActionsView?
    
    var swipeType: CollectionViewCellSwipeType = .none
    
    var swipeInitialFramePosition: CGFloat = 0
    var swipeStartPosition: CGPoint = .zero
    var swipePastBounds: Bool = false
    var deletePending: Bool = false
    var swipeVelocity: CGFloat = 0
    var originalStartPosition: CGPoint = .zero
    
    var swipeSnapshotView: UIView?
    
    var swipeTranslation: CGFloat = 0 {
        didSet {
            swipeSnapshotView?.transform = CGAffineTransform(translationX: swipeTranslation, y: 0)
        }
    }
    
    var minimumSwipeTrackingPosition: CGFloat {
        guard let actionsView = actionsView else { return 0 }
        return -actionsView.maximumWidth
    }
    
    public var actions: [CollectionViewCellAction] {
        get {
            return self.actionsView?.actions ?? []
        }
        set {
            self.actionsView?.actions = newValue
        }
    }
    
    var theme: Theme {
        get {
            return actionsView?.theme ?? Theme.standard
        }
        set {
            actionsView?.theme = newValue
        }
    }
    
    var actionsViewRect: CGRect {
        guard let actionsView = actionsView, actionsView.superview != nil else { return .zero }
        let bounds = actionsView.bounds
        let rect = self.convert(bounds, from: actionsView)
        return rect
    }
    
    func beginSwipe(with position: CGPoint, velocity: CGFloat) {
        swipeInitialFramePosition = contentView.frame.origin.x
        swipeStartPosition = position
        swipePastBounds = false
        
        showActionsView(with: swipeType)
        UIView.performWithoutAnimation {
            updateSwipe(with: position, velocity: velocity)
        }
    }
    
    func updateSwipe(with touchPosition: CGPoint, velocity: CGFloat) {
  
    }
    
    func showActionsView(with swipeType: CollectionViewCellSwipeType) {
        // We don't need to do this if the view is already visible.
        guard let actionsView = actionsView, actionsView.superview == nil else { return }
        
        layoutActionsView()
        actionsView.swipeType = swipeType

        contentView.addSubview(actionsView)
    }
    
    // MARK: Opening & closing action pane
    
    func takeSwipeSnapshot() {
        guard let snapshot = contentView.snapshotView(afterScreenUpdates: false) else {
            return
        }
        swipeSnapshotView = snapshot
        swipeSnapshotView?.backgroundColor = backgroundView?.backgroundColor
        snapshot.frame = contentView.bounds
        contentView.addSubview(snapshot)
    }
    
    func removeSwipeSnapshot() {
        swipeSnapshotView?.removeFromSuperview()
        swipeSnapshotView = nil
    }
    
    func openActionPane() {
        // Make sure we don't swipe twice on the same cell.
        guard let actionsView = actionsView, swipeTranslation >= 0 else { return }
        
        clipsToBounds = true
        
        let swipeType = actionsView.swipeType
        
        takeSwipeSnapshot()
        
        showActionsView(with: swipeType)
        
        let targetTranslation = swipeType == .primary ? minimumSwipeTrackingPosition : -minimumSwipeTrackingPosition
        
            let totalDistance = swipeTranslation - targetTranslation
            let duration: CGFloat = 0.40
            let springVelocity = abs(swipeVelocity) * duration / totalDistance
        
            UIView.animate(withDuration: TimeInterval(duration), delay: 0, usingSpringWithDamping: 10, initialSpringVelocity: springVelocity, options: .beginFromCurrentState, animations: {
                self.swipeTranslation = targetTranslation
            }, completion: { (finished: Bool) in
                actionsView.isUserInteractionEnabled = true
            })
    }
    
    func closeActionPane() {
        
        let targetTranslation = swipeType == .primary ? -swipeTranslation : swipeTranslation
        
        let totalDistance = targetTranslation
        let duration: CGFloat = 0.40
        let springVelocity = abs(swipeVelocity) * duration / totalDistance
        
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, usingSpringWithDamping: 10, initialSpringVelocity: springVelocity, options: .beginFromCurrentState, animations: {
            self.swipeTranslation = 0
        }, completion: { (finished: Bool) in
            self.removeActionsView()
            self.contentView.isUserInteractionEnabled = true
            self.actionsView?.isUserInteractionEnabled = false
            self.swipeInitialFramePosition = 0
            self.clipsToBounds = false
            self.removeSwipeSnapshot()
        })
    }
    
    func removeActionsView() {
        actionsView?.removeFromSuperview()
    }
    
    // MARK: Prepare for reuse
    
    func resetSwipeable() {
        deletePending = false
        swipePastBounds = false
        swipeTranslation = 0
    }
    
}
