import UIKit

@objc(WMFArticleCollectionViewCell) public class ArticleCollectionViewCell: WMFExploreCollectionViewCell {
    @IBOutlet weak var saveButton: SaveButton!

    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    static let estimatedHeight = 104
    
    public final var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            imageContainerView.isHidden = isImageViewHidden
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
    }
}
