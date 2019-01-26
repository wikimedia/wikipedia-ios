
class EditOptionView: ViewFromClassNib, Themeable  {
    @IBOutlet public var label: UILabel!
    @IBOutlet public var button: AutoLayoutSafeMultiLineButton!
    @IBOutlet public var toggle: UISwitch!
    @IBOutlet private var divider: UIView!
    var theme: Theme = .standard

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if subviews.count != 0 { // From: https://blog.compeople.eu/apps/?p=142
            return self
        }
        return type(of:self).wmf_viewFromClassNib()
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        divider.backgroundColor = theme.colors.tertiaryText
        label.textColor = theme.colors.primaryText
        button.titleLabel?.textColor = theme.colors.link
    }
}
