import UIKit

class NewsCollectionViewHeader: UICollectionReusableView, Themeable {
    @IBOutlet weak var label: UILabel!

    private var isFirstLayout = true

    override func awakeFromNib() {
        super.awakeFromNib()
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

    override func layoutSubviews() {
        super.layoutSubviews()
        if isFirstLayout {
            updateFonts()
            isFirstLayout = false
        }
    }
}
