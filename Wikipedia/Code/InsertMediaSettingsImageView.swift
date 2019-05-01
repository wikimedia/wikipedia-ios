import UIKit

final class InsertMediaSettingsImageView: UIView {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var headingLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
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
            titleLabel.text = title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.accessibilityIgnoresInvertColors = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headingLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        headingLabel.preferredMaxLayoutWidth = headingLabel.bounds.width
        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
    }
}

extension InsertMediaSettingsImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.link
        separatorView.backgroundColor = theme.colors.border
    }
}
