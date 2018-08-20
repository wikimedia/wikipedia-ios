
// UITextView with slight top and bottom gradients covering scrolling text.
class WMFGradientTextView : UITextView {
    private let fadeHeight = 6.0
    private var normalizedFadeHeight: Double {
        return bounds.size.height > 0 ? fadeHeight /  Double(bounds.size.height) : 0
    }

    private lazy var gradientMask: CAGradientLayer = {
        let mask = CAGradientLayer()
        mask.startPoint = .zero
        mask.endPoint = CGPoint(x: 0, y: 1)
        mask.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        layer.mask = mask
        return mask
    }()
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        guard layer == gradientMask.superlayer else {
            assertionFailure("Unexpected superlayer")
            return
        }

        // Keep fade heights fixed to `fadeHeight` regardless of text view height
        gradientMask.locations = [
            0.0,
            NSNumber(value: normalizedFadeHeight),          // upper stop
            NSNumber(value: 1.0 - normalizedFadeHeight),    // lower stop
            1.0
        ]

        // Maintain fixed mask location on scroll
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientMask.frame = CGRect(x: 0, y: contentOffset.y, width: bounds.size.width, height: bounds.size.height)
        CATransaction.commit()
    }
}

private extension CGFloat {
    func constrainedBetween(minHeight: Int, maxPercentOfScreenHeight: Int) -> CGFloat {
        assert(minHeight >= 0, "minHeight should be at least 0")
        assert(maxPercentOfScreenHeight <= 100, "maxPercentOfScreenHeight should be no more than 100")
        let screenHeight = UIScreen.main.bounds.size.height
        let proportionOfScreenHeight = screenHeight > 0.0 ? self / screenHeight : 0.0
        var constrainedHeight = self
        let maxAllowedProportionOfScreenHeight = CGFloat(maxPercentOfScreenHeight) / 100.0
        if (proportionOfScreenHeight > maxAllowedProportionOfScreenHeight) {
            constrainedHeight = screenHeight * maxAllowedProportionOfScreenHeight
        }
        return fmax(CGFloat(minHeight), constrainedHeight)
    }
}

private enum OpenStatePercent: Int {
    case normal = 22, maximized = 60
}

@objc class WMFScreenHeightConstrainedGradientTextView: WMFGradientTextView {
    private let minHeight = 30
    private var maxPercentOfScreenHeight: Int {
        get {
            return openStatePercent.rawValue
        }
    }
    
    private var openStatePercent: OpenStatePercent = .normal {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    @objc func toggleOpenState() {
        openStatePercent = openStatePercent == .normal ? .maximized : .normal
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        assert(contentCompressionResistancePriority(for: .vertical) == .required, "vertical contentCompressionResistancePriority must be `.required` for height to correctly account for text height.")
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = size.height.constrainedBetween(minHeight: minHeight, maxPercentOfScreenHeight: maxPercentOfScreenHeight)
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
