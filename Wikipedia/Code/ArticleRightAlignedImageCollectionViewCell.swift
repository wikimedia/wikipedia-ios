import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: WMFExploreCollectionViewCell, ArticleCollectionViewCell {
    public var imageHeight: CGFloat = 0

    open var imageWidth: Int {
        return traitCollection.wmf_nearbyThumbnailWidth
    }
    
    open class var nibName: String {
        return "ArticleRightAlignedImageCollectionViewCell"
    }
    
    open class var classNib: UINib {
        return UINib(nibName: nibName, bundle: nil)
    }
    
    @IBOutlet weak public var textContainerView: UIView?
    @IBOutlet weak public var titleLabel: UILabel?
    @IBOutlet weak public var descriptionLabel: UILabel?
    @IBOutlet weak public var extractLabel: UILabel?
    
    @IBOutlet weak public var imageView: UIImageView?
    @IBOutlet weak public var imageContainerView: UIView?
    @IBOutlet weak public var imageHeightConstraint: NSLayoutConstraint?
    
    @IBOutlet weak public var saveButton: SaveButton!
    @IBOutlet weak public var saveButtonContainerView: UIView?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.wmf_showPlaceholder()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton?.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemMedium, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        descriptionLabel?.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .body, compatibleWithTraitCollection: traitCollection)
    }
    
    public final var isImageViewHidden = false {
        didSet {
            imageView?.isHidden = isImageViewHidden
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
        imageView?.wmf_reset()
        imageView?.wmf_showPlaceholder()
        saveButton?.saveButtonState = .longSave
    }
    
    public func configure(article: WMFArticle, contentGroup: WMFContentGroup, layoutOnly: Bool) {
        if let imageURL = article.imageURL(forWidth: self.imageWidth) {
            isImageViewHidden = false
            if !layoutOnly {
                imageView?.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
            }
        } else {
            isImageViewHidden = true
        }
        
        titleLabel?.text = article.displayTitle
        let displayType = contentGroup.displayType()
        if displayType == .pageWithPreview {
            textContainerView?.backgroundColor = UIColor.white
            descriptionLabel?.text = article.wikidataDescription?.wmf_stringByCapitalizingFirstCharacter()
            extractLabel?.text = article.snippet
            isSaveButtonHidden = false
            imageHeight = 196
        } else {
            if displayType == .mainPage {
                descriptionLabel?.text = article.wikidataDescription ?? WMFLocalizedString("explore-main-page-description", value: "Main page of Wikimedia projects", comment: "Main page description that shows when the main page lacks a Wikidata description.")
            } else {
                descriptionLabel?.text = article.wikidataDescriptionOrSnippet?.wmf_stringByCapitalizingFirstCharacter()
            }
            
            textContainerView?.backgroundColor = displayType == .relatedPages ? UIColor.wmf_lightGrayCellBackground : UIColor.white
            extractLabel?.text = nil
            isSaveButtonHidden = true
            imageHeight = 150
        }
        
        let language = (article.url as NSURL?)?.wmf_language
        titleLabel?.accessibilityLanguage = language
        descriptionLabel?.accessibilityLanguage = language
        extractLabel?.accessibilityLanguage = language
    }
}
