import UIKit

class InsertMediaSettingsButtonView: UIView {
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var button: UIButton!

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        button.titleLabel?.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }
}

extension InsertMediaSettingsButtonView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        button.setTitleColor(theme.colors.secondaryText, for: .normal)
        button.tintColor = theme.colors.secondaryText
        separatorView.backgroundColor = theme.colors.border
    }
}
