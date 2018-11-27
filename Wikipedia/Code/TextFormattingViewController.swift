import UIKit

@objc(WMFTextFormattingViewControllerDelegate)
protocol TextFormattingViewControllerDelegate: class {
    func textFormattingViewControllerDidTapCloseButton(_ textFormattingViewController: TextFormattingViewController, button: UIButton)
}

@objc(WMFTextFormattingViewController)
class TextFormattingViewController: UIViewController {
    @objc weak var delegate: TextFormattingViewControllerDelegate?

    private var theme = Theme.standard

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    // buttons

    @IBOutlet weak var styleTitleLabel: UILabel!
    @IBOutlet weak var styleDisclosureButton: AlignedImageButton!

    @IBOutlet weak var textSizeTitleLabel: UILabel!
    @IBOutlet weak var textSizeDisclosureButton: AlignedImageButton!

    @IBOutlet weak var clearButton: UIButton!

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        titleLabel.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        styleTitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        styleDisclosureButton.titleLabel?.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        textSizeTitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        textSizeDisclosureButton.titleLabel?.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        clearButton.titleLabel?.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }

    @IBAction private func close(_ sender: UIButton) {
        delegate?.textFormattingViewControllerDidTapCloseButton(self, button: sender)
    }
}

extension TextFormattingViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        titleLabel.textColor = theme.colors.primaryText
        styleTitleLabel.textColor = theme.colors.primaryText
        textSizeTitleLabel.textColor = theme.colors.primaryText

        styleDisclosureButton.titleLabel?.textColor = theme.colors.primaryText
        textSizeDisclosureButton.titleLabel?.textColor = theme.colors.primaryText

        styleDisclosureButton.tintColor = UIColor.red

    }
}
