import UIKit

class InsertMediaSearchResultCollectionViewCell: CollectionViewCell {
    private let imageView = UIImageView()
    private let captionLabel = UILabel()

    private var imageURL: URL?
    private var imageViewDimension: CGFloat = 0

    private var spacing: CGFloat = 8

    private let selectedImageView = UIImageView()
    private var selectedImageViewDimension: CGFloat = 0
    private var selectedImage = UIImage(named: "selected")

    override func setup() {
        super.setup()
        imageView.accessibilityIgnoresInvertColors = true
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        selectedImageView.contentMode = .scaleAspectFit
        contentView.addSubview(selectedImageView)
        captionLabel.numberOfLines = 1
        contentView.addSubview(captionLabel)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        captionLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }

    override func reset() {
        super.reset()
        imageView.wmf_reset()
        captionLabel.text = nil
    }

    func configure(imageURL: URL?, imageViewDimension: CGFloat, title: String?) {
        self.imageURL = imageURL
        self.imageViewDimension = imageViewDimension
        selectedImageViewDimension = imageViewDimension / 6
        captionLabel.text = title
        setNeedsLayout()
    }

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        guard let imageURL = imageURL else {
            return .zero
        }

        let size = super.sizeThatFits(size, apply: apply)

        let isRTL = traitCollection.layoutDirection == .rightToLeft
        let x: CGFloat
        if isRTL {
            x = size.width
        } else {
            x = 0
        }

        var origin = CGPoint(x: x, y: 0)
        let height = max(origin.y, imageViewDimension)

        if (apply) {
            imageView.frame = CGRect(x: origin.x, y: origin.y, width: imageViewDimension, height: imageViewDimension)
            imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { error in
                self.imageView.image = UIImage(named: "media-wizard/placeholder")
            }, success: {})
            selectedImageView.frame = CGRect(x: imageView.frame.maxX - selectedImageViewDimension, y: imageView.frame.maxY - selectedImageViewDimension, width: selectedImageViewDimension, height: selectedImageViewDimension)
            selectedImageView.image = selectedImage
            origin.y += imageView.frame.layoutHeight(with: spacing)
        }

        selectedImageView.isHidden = !isSelected

        let semanticContentAttribute: UISemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight

        if captionLabel.wmf_hasAnyNonWhitespaceText {
            let captionLabelFrame = captionLabel.wmf_preferredFrame(at: origin, maximumWidth: imageViewDimension, alignedBy: semanticContentAttribute, apply: apply)
            origin.y += captionLabelFrame.height
        }

        captionLabel.isHidden = !captionLabel.wmf_hasAnyNonWhitespaceText

        return CGSize(width: size.width, height: height)
    }
}

extension InsertMediaSearchResultCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        selectedImage = theme.isDark ? UIImage(named: "selected-dark") : UIImage(named: "selected")
        selectedImageView.tintColor = theme.colors.link
        captionLabel.textColor = theme.colors.primaryText
        labelBackgroundColor = theme.colors.paperBackground
    }
}
