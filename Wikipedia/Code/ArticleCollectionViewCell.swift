import UIKit

@objc(WMFArticleCollectionViewCell)
open class ArticleCollectionViewCell: WMFExploreCollectionViewCell {
    open var imageWidth: Int {
        assert(false, "Subclassers must implement imageWidth")
        return 0
    }
    
    open class var nibName: String {
        assert(false, "Subclassers must implement nibName")
        return "ArticleCollectionViewCell"
    }
    
    open class var classNib: UINib {
        return UINib(nibName: nibName, bundle: nil)
    }
    
    @IBOutlet weak var textContainerView: UIView?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var extractLabel: UILabel?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageContainerView: UIView?
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint?

    @IBOutlet weak var saveButton: SaveButton?
    @IBOutlet weak var saveButtonContainerView: UIView?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        imageView.wmf_showPlaceholder()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton?.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .body, compatibleWithTraitCollection: traitCollection)
    }
    
    public final var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            imageContainerView?.isHidden = isImageViewHidden
        }
    }
    
    public final var isSaveButtonHidden = false {
        didSet {
            saveButton?.isHidden = isSaveButtonHidden
            saveButtonContainerView?.isHidden = isSaveButtonHidden
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        imageView.wmf_showPlaceholder()
        saveButton?.saveButtonState = .longSave
    }
}

extension ArticleCollectionViewCell {
    public func configure(article: WMFArticle, contentGroup: WMFContentGroup, layoutOnly: Bool) {
        if let imageURL = article.imageURL(forWidth: self.imageWidth) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        titleLabel.text = article.displayTitle
        if contentGroup.displayType() == WMFFeedDisplayType.pageWithPreview {
            textContainerView?.backgroundColor = UIColor.white
            descriptionLabel.text = article.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter()
            extractLabel?.text = article.snippet
            isSaveButtonHidden = false
            imageHeightConstraint?.constant = 196
        } else {
            descriptionLabel.text = article.wikidataDescriptionOrSnippet?.wmf_stringByCapitalizingFirstCharacter()
            textContainerView?.backgroundColor = UIColor.wmf_lightGrayCellBackground
            extractLabel?.text = nil
            if let _ = saveButtonContainerView { //hack check for FullWidth vs RightAligned
                isSaveButtonHidden = true
            } else {
                isSaveButtonHidden = false
            }
            imageHeightConstraint?.constant = 150
        }
    }
}
