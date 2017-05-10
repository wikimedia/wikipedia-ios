import UIKit

@objc(WMFArticleCollectionViewCell) public class ArticleCollectionViewCell: WMFExploreCollectionViewCell {
    
    open var estimatedHeight: CGFloat {
        return 0
    }
    
    open var imageWidth: Int {
        return 0
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var imageContainerView: UIView?
    @IBOutlet weak var saveButton: SaveButton?
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton?.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    public final var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            imageContainerView?.isHidden = isImageViewHidden
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
    }
}
