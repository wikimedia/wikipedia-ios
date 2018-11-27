import UIKit

@objc(WMFTextFormattingViewDelegate)
protocol TextFormattingViewDelegate: class {
    func textFormattingViewDidTapCloseButton(_ textFormattingView: TextFormattingView, button: UIButton)
}

@objc(WMFTextFormattingView)
class TextFormattingView: UIView {
    @objc weak var delegate: TextFormattingViewDelegate?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var styleTitleLabel: UILabel!
    @IBOutlet weak var styleDisclosureButton: AlignedImageButton!
    @IBOutlet weak var textSizeTitleLabel: UILabel!
    @IBOutlet weak var textSizeDisclosureButton: AlignedImageButton!
    @IBOutlet weak var clearButton: UIButton!

    @objc static func loadFromNib() -> TextFormattingView {
        let nib = UINib(nibName: "TextFormattingView", bundle: Bundle.main)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! TextFormattingView
        return view
    }

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
        delegate?.textFormattingViewDidTapCloseButton(self, button: sender)
    }

}

extension TextFormattingView: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        styleTitleLabel.textColor = theme.colors.primaryText
        textSizeTitleLabel.textColor = theme.colors.primaryText

        styleDisclosureButton.titleLabel?.textColor = theme.colors.primaryText
        textSizeDisclosureButton.titleLabel?.textColor = theme.colors.primaryText

        styleDisclosureButton.tintColor = UIColor.red
    }
}
