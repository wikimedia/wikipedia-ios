import UIKit

@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: CollectionViewCell {
    static let defaultMargins = UIEdgeInsetsMake(15, 13, 15, 13)
    
    @objc public let titleLabel = UILabel()
    @objc public let descriptionLabel = UILabel()
    @objc public let imageView = UIImageView()
    @objc public let saveButton = SaveButton()
    @objc public var extractLabel: UILabel?
    @objc public let actionsView = CollectionViewCellActionsView()
    
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
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        if apply {
            contentView.frame = CGRect(origin: CGPoint(x: swipeTranslation, y: 0), size: size)
            let actionsViewWidth = abs(swipeTranslation)
            let isRTL = actionsView.semanticContentAttribute == .forceRightToLeft
            let x = isRTL ? 0 : size.width - actionsViewWidth
            actionsView.frame = CGRect(x: x, y: 0, width: actionsViewWidth, height: size.height)
            actionsView.layoutIfNeeded()
        }
        return size
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

    var swipeVelocity: CGFloat = 0
    var isSwiping: Bool = false {
        didSet {
            if isSwiping && actionsView.superview == nil {
                insertSubview(actionsView, belowSubview: contentView)
                clipsToBounds = true
            } else if !isSwiping && actionsView.superview != nil {
                actionsView.removeFromSuperview()
                clipsToBounds = false
            }
        }
    }
    
    public var swipeTranslation: CGFloat = 0 {
        didSet {
            assert(!swipeTranslation.isNaN && swipeTranslation.isFinite)
            setNeedsLayout()
        }
    }
    
    var minimumSwipeTrackingPosition: CGFloat {
        return -actionsView.maximumWidth
    }
    
    func showActionsView(with swipeType: CollectionViewCellSwipeType) {
        // We don't need to do this if the view is already visible.
        guard actionsView.superview == nil else { return }
        
        insertSubview(actionsView, belowSubview: contentView)
        layoutSubviews()
        actionsView.layoutIfNeeded()
    }
    
    // MARK: Opening & closing action pane
    
    func openActionPane() {
        let isRTL = actionsView.semanticContentAttribute == .forceRightToLeft
        let targetTranslation =  isRTL ? actionsView.maximumWidth : 0 - actionsView.maximumWidth
        isSwiping = true
        animateActionPane(to: targetTranslation) { (finished) in }
    }
    
    func closeActionPane() {
        animateActionPane(to: 0) { (finished) in
            self.isSwiping = false
        }
    }
    
    func animateActionPane(to targetTranslation: CGFloat, completion: @escaping (Bool) -> Void) {
        let initialSwipeTranslation = swipeTranslation
        let animationTranslation = targetTranslation - initialSwipeTranslation
        let velocityIsInDirectionOfTranslation = swipeVelocity.sign == animationTranslation.sign
        let animationDistance = abs(animationTranslation)
        let swipeSpeed = abs(swipeVelocity)
        var animationSpeed = swipeSpeed
        var overshootTranslation: CGFloat = 0
        var overshootDistance: CGFloat = 0
        var secondKeyframeDuration: TimeInterval = 0
        if !velocityIsInDirectionOfTranslation || swipeSpeed < 500 {
            animationSpeed = 500
        } else {
            secondKeyframeDuration = TimeInterval(animationSpeed) / 50000
            overshootDistance = sqrt(animationSpeed * CGFloat(secondKeyframeDuration))
            overshootTranslation = animationTranslation < 0 ? -overshootDistance :  overshootDistance
        }
        let firstKeyframeDuration = TimeInterval(animationDistance / animationSpeed)
        let shouldOvershoot = overshootDistance > 0
        let thirdKeyframeDuration = 2 * secondKeyframeDuration
        let curve = shouldOvershoot ? UIViewAnimationOptions.curveEaseOut : UIViewAnimationOptions.curveEaseInOut
        // hacky but OK for now - built in spring animation left gaps between buttons on bounces
        UIView.animate(withDuration: firstKeyframeDuration + secondKeyframeDuration, delay: 0, options: [.beginFromCurrentState, curve], animations: {
            self.swipeTranslation = targetTranslation + overshootTranslation
            self.layoutSubviews()
        }) { (done) in
            guard shouldOvershoot else {
                completion(done)
                return
            }
            UIView.animate(withDuration: thirdKeyframeDuration, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                self.swipeTranslation = targetTranslation
                self.layoutSubviews()
            }) { (done) in
                completion(done)
            }
        }
    }
    
    // MARK: Prepare for reuse
    
    func resetSwipeable() {
        swipeTranslation = 0
        swipeVelocity = 0
    }
}
