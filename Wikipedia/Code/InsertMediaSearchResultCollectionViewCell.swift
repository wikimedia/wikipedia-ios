import UIKit

class InsertMediaSearchResultCollectionViewCell: CollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private var imageViewDimension: CGFloat = 70
    private var spacing: CGFloat = 8

    var title: String? {
        didSet {
            setNeedsLayout()
        }
    }

    var imageURL: URL? {
        didSet {
            backgroundColor = UIColor.purple
            setNeedsLayout()
        }
    }

    override func setup() {
        super.setup()
        imageView.accessibilityIgnoresInvertColors = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        titleLabel.numberOfLines = 1
        addSubview(titleLabel)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }

    override func reset() {
        super.reset()
        imageView.wmf_reset()
        titleLabel.text = nil
    }

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        guard let imageURL = imageURL else {
            return .zero
        }

        let size = super.sizeThatFits(size, apply: apply)
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        let widthMinusMargins = layoutWidth(for: size)

        let isRTL = traitCollection.layoutDirection == .rightToLeft
        let x: CGFloat
        if isRTL {
            x = size.width - widthMinusMargins
        } else {
            x = layoutMargins.left
        }

        var origin = CGPoint(x: x, y: layoutMargins.top)
        let height = max(origin.y, minHeight)

        if (apply) {
            let imageViewX = layoutMargins.left
            let imageViewY = layoutMargins.top
            imageView.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { error in
                self.imageView.image = UIImage(named: "media-wizard/placeholder")
            }, success: {})
            origin.y += imageView.frame.layoutHeight(with: spacing)
        }

        let semanticContentAttribute: UISemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight

        if titleLabel.wmf_hasAnyNonWhitespaceText {
            let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, maximumWidth: imageViewDimension, alignedBy: semanticContentAttribute, apply: apply)
            origin.y += titleLabelFrame.height
        }

        titleLabel.isHidden = !titleLabel.wmf_hasAnyNonWhitespaceText

        return CGSize(width: size.width, height: height)
    }
}
