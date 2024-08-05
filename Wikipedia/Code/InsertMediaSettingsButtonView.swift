import WMFComponents

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
        button.titleLabel?.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }

    @IBAction private func delegateButtonAction(_ sender: UIButton) {
        buttonAction?(sender)
    }
}

extension InsertMediaSettingsButtonView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        button.setTitleColor(theme.colors.link, for: .normal)
        separatorView.backgroundColor = .clear
    }
}
