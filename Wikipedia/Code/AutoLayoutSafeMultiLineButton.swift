
// See multi-line button thread: https://stackoverflow.com/q/23845982/135557
@IBDesignable
class AutoLayoutSafeMultiLineButton: UIButton {
    func multiLineSafeSetup () {
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.adjustsFontSizeToFitWidth = false
        setContentHuggingPriority(.defaultLow + 1, for: .vertical)
        setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        multiLineSafeSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        multiLineSafeSetup()
    }
    
    override var intrinsicContentSize: CGSize {
        guard let titleLabel = titleLabel else {
            return super.intrinsicContentSize
        }
        return sizeByAddingInsets(to: titleLabel.intrinsicContentSize)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let titleLabel = titleLabel else {
            return super.sizeThatFits(size)
        }
        return sizeByAddingInsets(to: titleLabel.sizeThatFits(size))
    }
    
    private var isSafeToLayoutSubviews = true // Recursion guard for setting `titleLabel.preferredMaxLayoutWidth` within `layoutSubviews()`.
    override func layoutSubviews() {
        guard isSafeToLayoutSubviews else {
            isSafeToLayoutSubviews = true
            return
        }
        guard let titleLabel = titleLabel else {
            super.layoutSubviews()
            return
        }
        isSafeToLayoutSubviews = false
        titleLabel.preferredMaxLayoutWidth = titleLabel.frame.width
        isSafeToLayoutSubviews = true
        super.layoutSubviews()
    }
    
    private func sizeByAddingInsets(to size: CGSize) -> CGSize {
        return CGSize(
            width: size.width + titleEdgeInsets.left + titleEdgeInsets.right,
            height: size.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        )
    }
}
