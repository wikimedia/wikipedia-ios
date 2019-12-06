import UIKit

class PageHistoryFilterCountCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageLabel: UILabel!

    @IBOutlet private weak var rightSeparator: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        updateFonts()
        isAccessibilityElement = true
    }

    @IBOutlet private var sizingOnlyWidthConstraint: NSLayoutConstraint!

    func sizeWith(width: CGFloat, title: String, image: UIImage?, imageText: String, isRightSeparatorHidden: Bool) -> CGSize {
        if sizingOnlyWidthConstraint.constant != width {
            sizingOnlyWidthConstraint.constant = width
        }
        configure(with: title, image: image, imageText: imageText, isRightSeparatorHidden: isRightSeparatorHidden)
        setNeedsLayout()
        layoutIfNeeded()
        return systemLayoutSizeFitting(UIView.layoutFittingCompressedSize,
                                            withHorizontalFittingPriority: UILayoutPriority.defaultHigh,
                                            verticalFittingPriority: UILayoutPriority.defaultLow)
    }

    private func updateFonts() {
        imageLabel.font = UIFont.wmf_font(.callout, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    func configure(with title: String, image: UIImage?, imageText: String, isRightSeparatorHidden: Bool) {
        titleLabel.text = title
        imageView.image = image
        imageLabel.text = imageText
        rightSeparator.isHidden = isRightSeparatorHidden
        updateAccessibilityLabel()
    }

    private func updateAccessibilityLabel() {
        accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [imageLabel.text, titleLabel.text])
    }
}

extension PageHistoryFilterCountCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        rightSeparator.backgroundColor = theme.colors.border
        imageLabel.textColor = theme.colors.primaryText
        titleLabel.textColor = theme.colors.secondaryText
        imageView.tintColor = theme.colors.link
    }
}
