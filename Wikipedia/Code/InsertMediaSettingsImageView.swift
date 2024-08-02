import WMFComponents

final class InsertMediaSettingsImageView: UIView {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageDescriptionLabel: UILabel!
    @IBOutlet private weak var titleButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet private weak var separatorView: UIView!

    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    var imageDescription: String? {
        didSet {
            imageDescriptionLabel.text = imageDescription
        }
    }

    var title: String? {
        didSet {
            titleButton.setAttributedTitle(getImageLinkButtonTitle(), for: .normal)
        }
    }

    var titleURL: URL?
    var titleAction: ((URL) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.accessibilityIgnoresInvertColors = true
        updateFonts()
        configTitleButton()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        imageDescriptionLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        titleButton.titleLabel?.font = WMFFont.for(.boldHeadline, compatibleWith: traitCollection)
    }

    @IBAction private func performTitleAction(_ sender: UIButton) {
        guard let url = titleURL else {
            assertionFailure("titleURL should be set by now")
            return
        }
        titleAction?(url)
    }

    private func getImageLinkButtonTitle() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString()
        if let imageAttachment = UIImage(named: "mini-external") {
            let attachment = NSTextAttachment(image: imageAttachment)
            attributedString.append(NSAttributedString(string: title ?? String()))
            attributedString.append(NSAttributedString(string: "  "))
            attributedString.append(NSAttributedString(attachment: attachment))
        }
        return attributedString
    }

    private func configTitleButton() {
        titleButton.configuration?.contentInsets = .zero
        titleButton.configuration?.titlePadding = .zero
    }
}

extension InsertMediaSettingsImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        imageDescriptionLabel.textColor = theme.colors.secondaryText
        titleButton.setTitleColor(theme.colors.link, for: .normal)
        separatorView.backgroundColor = theme.colors.border
    }
}
