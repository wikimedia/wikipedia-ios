import UIKit

final class InsertMediaSettingsButtonView: UIView {
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var button: UIButton!

    var buttonTitle: String? {
        didSet {
            button.setTitle(buttonTitle, for: .normal)
            updateFonts()
        }
    }

    var buttonAction: ((UIButton) -> Void)?

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        button.titleLabel?.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }

    @IBAction private func delegateButtonAction(_ sender: UIButton) {
        buttonAction?(sender)
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
