
class WMFAuthLinkLabel: UILabel {
    override open func awakeFromNib() {
        super.awakeFromNib()
        textColor = UIColor.wmf_blueTint()
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        textAlignment = .natural
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        font = UIFont.wmf_preferredFontForFontFamily(WMFFontFamily.systemBold, withTextStyle: .subheadline, compatibleWithTraitCollection: self.traitCollection)
    }
}
