
/// Button configured with common auth style settings which also updates layer border color on "isEnabled" state change.
class WMFAuthButton: UIButton {
    override open var isEnabled:Bool{
        didSet {
            layer.borderColor = borderColor(forIsEnabled: isEnabled)
        }
    }
    fileprivate func borderColor(forIsEnabled enabled:Bool) -> CGColor{
        return enabled ? UIColor.wmf_blue.cgColor : UIColor.lightGray.cgColor
    }
    override open func awakeFromNib() {
        super.awakeFromNib()
        tintColor = .wmf_blue
        layer.borderWidth = 1.0
        layer.cornerRadius = 5
        layer.borderColor = borderColor(forIsEnabled: isEnabled)
    }
}
