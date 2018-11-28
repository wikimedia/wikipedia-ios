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

    @IBOutlet var separators: [UIView] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        addTopShadow()
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

    // MARK: Shadow

    private func addTopShadow() {
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height + 1)
    }

}

extension TextFormattingView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.midBackground

        titleLabel.textColor = theme.colors.primaryText
        styleTitleLabel.textColor = theme.colors.primaryText
        textSizeTitleLabel.textColor = theme.colors.primaryText

        styleDisclosureButton.setTitleColor(theme.colors.primaryText, for: .normal)
        textSizeDisclosureButton.setTitleColor(theme.colors.primaryText, for: .normal)

        clearButton.tintColor = theme.colors.error

        separators.forEach { $0.backgroundColor = theme.colors.border }

        layer.shadowColor = theme.colors.shadow.cgColor
    }
}
