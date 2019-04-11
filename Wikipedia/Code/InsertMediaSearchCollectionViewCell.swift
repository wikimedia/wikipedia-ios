import UIKit

class InsertMediaSearchCollectionViewCell: CollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private var imageViewDimension: CGFloat = 70

    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil
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
}
