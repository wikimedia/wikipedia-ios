import UIKit

class InsertMediaSettingsImageView: UIView {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var headingLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headingLabel.font = UIFont.wmf_font(.caption1, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        headingLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
    }
}

extension InsertMediaSettingsImageView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.link
    }
}
