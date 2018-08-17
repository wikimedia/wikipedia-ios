
class WMFGradientTextView : UITextView {
    private let fadeHeight: CGFloat = 6
    private let fadeColor = UIColor.black
    private let clear = UIColor.black.withAlphaComponent(0)
    private lazy var topGradientView: WMFGradientView = {
        let gradient = WMFGradientView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.startPoint = .zero
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.setStart(fadeColor, end: clear)
        addSubview(gradient)
        return gradient
    }()
    
    private lazy var bottomGradientView: WMFGradientView = {
        let gradient = WMFGradientView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = .zero
        gradient.setStart(fadeColor, end: clear)
        addSubview(gradient)
        return gradient
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateGradientFrames()
    }
    
    private func updateGradientFrames() {
        topGradientView.frame = CGRect(x: 0, y: contentOffset.y, width: bounds.size.width, height: fadeHeight)
        bottomGradientView.frame = topGradientView.frame.offsetBy(dx: 0, dy: bounds.size.height - fadeHeight)
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
        if (constrainedHeight < CGFloat(minHeight)) {
            constrainedHeight = CGFloat(minHeight)
        }
        return constrainedHeight
    }
}

@objc class WMFScreenHeightConstrainedGradientTextView : WMFGradientTextView {
    private let minHeight = 30
    private let maxPercentOfScreenHeight = 22
    
    override var intrinsicContentSize: CGSize {
        let previousIsScrollEnabled = isScrollEnabled
        isScrollEnabled = false // "isScrollEnabled must be `false` for super.intrinsicContentSize to correctly account for text height: https://stackoverflow.com/a/45070888/135557
        assert(contentCompressionResistancePriority(for: .vertical) == .required, "vertical contentCompressionResistancePriority must be `.required` for height to correctly account for text height.")
        let superSize = super.intrinsicContentSize
        isScrollEnabled = previousIsScrollEnabled
        let constrainedHeight = superSize.height.constrainedBetween(minHeight: minHeight, maxPercentOfScreenHeight: maxPercentOfScreenHeight)
        return CGSize(width: superSize.width, height: constrainedHeight)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setContentOffset(.zero, animated: false)
        invalidateIntrinsicContentSize() // Needed so height is correctly adjusted on rotation.
    }
}
