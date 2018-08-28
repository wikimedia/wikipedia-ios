
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let titleLabel = titleLabel {
            titleLabel.preferredMaxLayoutWidth = titleLabel.frame.width
        }
    }
    
    private func sizeByAddingInsets(to size: CGSize) -> CGSize {
        return CGSize.init(
            width: size.width + titleEdgeInsets.left + titleEdgeInsets.right,
            height: size.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        )
    }
}
