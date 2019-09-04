import UIKit

final class InsertMediaSettingsImageView: UIView {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var headingLabel: UILabel!
    @IBOutlet private weak var titleButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet private weak var separatorView: UIView!

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    var heading: String? {
        didSet {
            headingLabel.text = heading
        }
    }

    var title: String? {
        didSet {
            titleButton.setTitle(title, for: .normal)
        }
    }

    var titleURL: URL?
    var titleAction: ((URL) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.accessibilityIgnoresInvertColors = true
        updateFonts()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        headingLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        titleButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        headingLabel.preferredMaxLayoutWidth = headingLabel.bounds.width
    }

    @IBAction private func performTitleAction(_ sender: UIButton) {
        guard let url = titleURL else {
            assertionFailure("titleURL should be set by now")
            return
        }
        titleAction?(url)
    }
}

extension InsertMediaSettingsImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleButton.setTitleColor(theme.colors.link, for: .normal)
        separatorView.backgroundColor = theme.colors.border
    }
}
