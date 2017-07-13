
/// Button configured with common auth style settings which also updates layer border color on "isEnabled" state change.
class WMFAuthButton: UIButton, Themeable {
    fileprivate var theme: Theme = Theme.standard
    
    override open var isEnabled:Bool{
        didSet {
            layer.borderColor = borderColor(forIsEnabled: isEnabled)
        }
    }
    fileprivate func borderColor(forIsEnabled enabled:Bool) -> CGColor{
        return enabled ? tintColor.cgColor : theme.colors.midBackground.cgColor
    }
    override open func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 1.0
        layer.cornerRadius = 5
        apply(theme: self.theme)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        setTitleColor(theme.colors.midBackground, for: .disabled)
        layer.borderColor = borderColor(forIsEnabled: isEnabled)
        setNeedsDisplay()
    }
}
