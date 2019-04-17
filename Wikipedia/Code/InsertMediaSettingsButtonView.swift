import UIKit

class InsertMediaSettingsButtonView: UIView {
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var button: UIButton!

    var buttonTitle: String? {
        didSet {
            button.setTitle(buttonTitle, for: .normal)
        }
    }

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
