@IBDesignable
class AutoLayoutSafeMultiLineButton: SetupButton {
    override func setup() {
        super.setup()
        titleLabel?.numberOfLines = 0
    }

    override var intrinsicContentSize: CGSize {
        return wmf_sizeThatFits(CGSize(width: bounds.size.width, height: UIView.noIntrinsicMetric))
    }
}
