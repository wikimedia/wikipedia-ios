import UIKit

final class InsertMediaSearchResultCollectionViewCell: CollectionViewCell {
    let imageView = UIImageView()
    private let captionLabel = UILabel()

    private var imageURL: URL?

    private var spacing: CGFloat = 8

    private let selectedImageView = UIImageView()
    private var selectedImage = UIImage(named: "selected")

    override func setup() {
        super.setup()
        isAccessibilityElement = true
        imageView.accessibilityIgnoresInvertColors = true
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        selectedImageView.contentMode = .scaleAspectFit
        contentView.addSubview(selectedImageView)
        captionLabel.numberOfLines = 1
        contentView.addSubview(captionLabel)
        captionLabel.isAccessibilityElement = true
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

    func configure(imageURL: URL?, caption: String?) {
        self.imageURL = imageURL
        captionLabel.text = caption
        accessibilityValue = caption
        setNeedsLayout()
    }

    override var isSelected: Bool {
        didSet {
            updateSelectedOrHighlighted()
            selectedImageView.isHidden = !isSelected
        }
    }

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        guard let imageURL = imageURL else {
            return super.sizeThatFits(size, apply: apply)
        }

        let imageViewDimension = size.width
        let selectedImageViewDimension = min(35, imageViewDimension * 0.2)
        
        guard let scaledImageURL = WMFParseSizePrefixFromSourceURL(imageURL) < Int(imageViewDimension) ? URL(string: WMFChangeImageSourceURLSizePrefix(imageURL.absoluteString, Int(imageViewDimension))) : imageURL else {
            return super.sizeThatFits(size, apply: apply)
        }

        let size = super.sizeThatFits(size, apply: apply)

        var origin = CGPoint(x: 0, y: 0)
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let height = max(origin.y, minHeight)

        if (apply) {
            imageView.frame = CGRect(x: origin.x, y: origin.y, width: imageViewDimension, height: imageViewDimension)
            imageView.wmf_setImage(with: scaledImageURL, detectFaces: false, onGPU: true, failure: {_ in }, success: {
                self.imageView.backgroundColor = .clear
            })
            selectedImageView.frame = CGRect(x: imageView.frame.maxX - selectedImageViewDimension, y: imageView.frame.maxY - selectedImageViewDimension, width: selectedImageViewDimension, height: selectedImageViewDimension)
            selectedImageView.image = selectedImage
            origin.y += imageView.frame.layoutHeight(with: spacing)
        }

        selectedImageView.isHidden = !isSelected

        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight

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
        backgroundColor = theme.colors.paperBackground
        imageView.backgroundColor = .clear
        selectedImage = theme.isDark ? UIImage(named: "selected-dark") : UIImage(named: "selected")
        selectedImageView.tintColor = theme.colors.link
        captionLabel.textColor = theme.colors.primaryText
    }
}
