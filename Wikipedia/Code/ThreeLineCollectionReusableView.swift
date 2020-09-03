import UIKit

class ThreeLineCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var topSmallLine: UILabel!
    @IBOutlet weak var middleLargeLine: UILabel!
    @IBOutlet weak var bottomSmallLine: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
    }

    private func updateFonts() {
        topSmallLine.font = UIFont.wmf_font(.semiboldBody, compatibleWithTraitCollection: traitCollection)
        bottomSmallLine.font = UIFont.wmf_font(.semiboldBody, compatibleWithTraitCollection: traitCollection)
        middleLargeLine.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
    }
}

extension ThreeLineCollectionReusableView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        topSmallLine.textColor = theme.colors.secondaryText
        bottomSmallLine.textColor = theme.colors.secondaryText
        middleLargeLine.textColor = theme.colors.primaryText
    }
}
