import UIKit

class NewsCollectionViewHeader: UICollectionReusableView, Themeable {
    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        wmf_configureSubviewsForDynamicType()
    }
    
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        label.textColor = theme.colors.primaryText
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        label.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
    }
}
