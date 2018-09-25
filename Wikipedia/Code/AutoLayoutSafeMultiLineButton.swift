@IBDesignable
class AutoLayoutSafeMultiLineButton: SetupButton {
    override func setup() {
        super.setup()
        titleLabel?.numberOfLines = 0
        assert(wmf_hasRequiredNonZeroHeightConstraint() == false, "Multiline button should not have any UILayoutPriority.required height constraints. Remove the height constraint or lower its priority.")
    }

    override var intrinsicContentSize: CGSize {
        return wmf_sizeThatFits(CGSize(width: bounds.size.width, height: UIView.noIntrinsicMetric))
    }
}
