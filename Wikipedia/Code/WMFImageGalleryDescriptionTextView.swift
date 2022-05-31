private extension CGFloat {
    func constrainedBetween(minHeight: Int, maxPercentOfScreenHeight: Int, availableHeight: CGFloat) -> CGFloat {
        assert(minHeight >= 0, "minHeight should be at least 0")
        assert(maxPercentOfScreenHeight <= 100, "maxPercentOfScreenHeight should be no more than 100")
        let proportionOfScreenHeight = availableHeight > 0.0 ? self / availableHeight : 0.0
        var constrainedHeight = self
        let maxAllowedProportionOfScreenHeight = CGFloat(maxPercentOfScreenHeight) / 100.0
        if proportionOfScreenHeight > maxAllowedProportionOfScreenHeight {
            constrainedHeight = availableHeight * maxAllowedProportionOfScreenHeight
        }
        return fmax(CGFloat(minHeight), constrainedHeight)
    }
}

@objc public enum GalleryDescriptionOpenStatePercent: Int {
    case normal = 22, maximized = 60
}

@objcMembers class WMFImageGalleryDescriptionTextView: UITextView {
    public var availableHeight: CGFloat = 0

    private let minHeight = 30
    private var maxPercentOfScreenHeight: Int {
        return openStatePercent.rawValue
    }
    
    public var openStatePercent: GalleryDescriptionOpenStatePercent = .normal {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public func toggleOpenState() {
        let overflowTextExists = contentSize.height > bounds.size.height
        guard overflowTextExists || openStatePercent == .maximized else {
            return
        }
        openStatePercent = openStatePercent == .normal ? .maximized : .normal
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        assert(contentCompressionResistancePriority(for: .vertical) == .required, "vertical contentCompressionResistancePriority must be `.required` for height to correctly account for text height.")
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = size.height.constrainedBetween(minHeight: minHeight, maxPercentOfScreenHeight: maxPercentOfScreenHeight, availableHeight: availableHeight)
        return size
    }

    override func invalidateIntrinsicContentSize() {
        isScrollEnabled = false // UITextView intrinsicContentSize only works when scrolling is false
        super.invalidateIntrinsicContentSize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        isScrollEnabled = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setContentOffset(.zero, animated: false)
        invalidateIntrinsicContentSize() // Needed so height is correctly adjusted on rotation.
    }
}
