import UIKit

@objc(WMFArticleCollectionViewCell) public class ArticleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var saveButton: SaveButton!
    @IBOutlet var textTrailingConstraints: [NSLayoutConstraint]!
    @IBOutlet weak var textLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    static let estimatedHeight = 104
    
    public final var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            let constant = isImageViewHidden ? textLeadingConstraint.constant : 2*textLeadingConstraint.constant + imageView.frame.size.width
            for textTrailingConstraint in textTrailingConstraints {
                textTrailingConstraint.constant = constant
            }

        }
    }
}
