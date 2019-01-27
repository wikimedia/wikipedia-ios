
class EditOptionView: EmbeddableView, Themeable  {
    @IBOutlet public var label: UILabel!
    @IBOutlet public var button: AutoLayoutSafeMultiLineButton!
    @IBOutlet public var toggle: UISwitch!
    @IBOutlet private var divider: UIView!
    var theme: Theme = .standard    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        divider.backgroundColor = theme.colors.tertiaryText
        label.textColor = theme.colors.primaryText
        button.titleLabel?.textColor = theme.colors.link
    }
}
