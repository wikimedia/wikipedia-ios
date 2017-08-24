import UIKit

@objc(WMFArticleListTableViewCell)
class ArticleListTableViewCell: ContainerTableViewCell {

    var articleCell: ArticleRightAlignedImageCollectionViewCell {
        return collectionViewCell as! ArticleRightAlignedImageCollectionViewCell
    }
    
    override func setup() {
        collectionViewCell = ArticleRightAlignedImageCollectionViewCell()
        addSubview(collectionViewCell)
        reset()
        super.setup()
    }
    
    func reset() {
        separatorInset = .zero
        articleCell.isSaveButtonHidden = true
        articleCell.imageViewDimension = 40
        articleCell.margins = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        articleCell.titleTextStyle = .subheadline
        articleCell.descriptionTextStyle = .footnote
        articleCell.updateFonts(with: traitCollection)
    }

    @objc static var estimatedRowHeight: CGFloat = 60
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionViewCell.frame = bounds
    }
    
    open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return articleCell.sizeThatFits(targetSize)
    }
    
    var titleText: String? {
        set {
            articleCell.titleLabel.text = newValue
        }
        get {
            return articleCell.titleLabel.text
        }
    }
    
    var descriptionText: String? {
        set {
            articleCell.descriptionLabel.text = newValue
        }
        get {
            return articleCell.descriptionLabel.text
        }
    }
    
    var imageURL: URL? {
        set {
            guard let newURL = newValue else {
                articleCell.isImageViewHidden = true
                articleCell.imageView.wmf_reset()
                return
            }
            articleCell.isImageViewHidden = false
            articleCell.imageView.wmf_setImage(with: newURL, detectFaces: true, onGPU: true, failure: { (error) in
                
            }, success: { 
                
            })
        }
        get {
            return articleCell.imageView.wmf_imageURLToFetch
        }
    }
    
    @objc(setTitleText:highlightingText:locale:)
    func set(titleTextToAttribute: String?, highlightingText: String?, locale: Locale?) {
        guard let titleTextToAttribute = titleTextToAttribute, let titleFont = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline) else {
            self.titleText = nil
            return
        }
        let attributedTitle = NSMutableAttributedString(string: titleTextToAttribute, attributes: [NSAttributedStringKey.font: titleFont])
        if let highlightingText = highlightingText {
            let range = (titleTextToAttribute.lowercased(with: locale) as NSString).range(of: highlightingText.lowercased(with: locale))
            if !WMFRangeIsNotFoundOrEmpty(range), let boldFont = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .subheadline) {
                attributedTitle.setAttributes([NSAttributedStringKey.font: boldFont], range: range)
            }
        }
        articleCell.titleTextStyle = nil
        articleCell.titleFontFamily = nil
        articleCell.titleLabel.attributedText = attributedTitle
    }
}
