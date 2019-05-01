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

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.accessibilityIgnoresInvertColors = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headingLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        titleButton.titleLabel?.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        headingLabel.preferredMaxLayoutWidth = headingLabel.bounds.width
    }
}

extension InsertMediaSettingsImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleButton.tintColor = theme.colors.link
        separatorView.backgroundColor = theme.colors.border
    }
}
