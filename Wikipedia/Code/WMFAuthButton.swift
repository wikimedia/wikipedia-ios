
/// Button configured with common auth style settings which also updates layer border color on "isEnabled" state change.
class WMFAuthButton: AutoLayoutSafeMultiLineButton, Themeable {
    fileprivate var theme: Theme = Theme.standard
    
    override open var isEnabled:Bool{
        didSet {
            layer.borderColor = borderColor(forIsEnabled: isEnabled)
        }
    }
    fileprivate func borderColor(forIsEnabled enabled:Bool) -> CGColor? {
        return enabled ? tintColor.cgColor : titleColor(for: .disabled)?.cgColor
    }
    override open func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 5
        titleEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        apply(theme: self.theme)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.cardButtonBackground
        setTitleColor(theme.colors.unselected, for: .disabled)
        setNeedsDisplay()
    }
}
