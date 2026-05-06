import WMFComponents

class NewsCollectionViewHeader: UICollectionReusableView, Themeable {
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        wmf_configureSubviewsForDynamicType()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { [weak self] (view: Self, previousTraitCollection: UITraitCollection) in
            guard let self else { return }
            self.updateFonts()
        }
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        label.textColor = theme.colors.primaryText
    }

    private func updateFonts() {
        label.font = WMFFont.for(.boldSubheadline, compatibleWith: traitCollection)
    }
}
