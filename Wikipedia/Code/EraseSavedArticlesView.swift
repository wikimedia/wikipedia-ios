import WMFComponents

class EraseSavedArticlesView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var footerLabel: UILabel!
    
    private var theme = Theme.standard

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    func updateFonts() {
        button.titleLabel?.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }
}

extension EraseSavedArticlesView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        titleLabel.textColor = theme.colors.primaryText
        titleLabel.backgroundColor = theme.colors.paperBackground
        footerLabel.textColor = theme.colors.secondaryText
        imageView.tintColor = theme.colors.icon == nil ? WMFColor.white : theme.colors.icon
        imageView.backgroundColor = theme.colors.iconBackground == nil ? WMFColor.red600 : theme.colors.iconBackground
        separatorView.backgroundColor = theme.colors.border
        footerLabel.backgroundColor = theme.colors.paperBackground
        button.titleLabel?.backgroundColor = theme.colors.paperBackground
    }
}
