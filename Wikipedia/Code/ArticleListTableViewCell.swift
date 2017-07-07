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
        articleCell.isSaveButtonHidden = true
        articleCell.imageViewDimension = 30
        articleCell.margins = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        articleCell.titleTextStyle = .subheadline
        articleCell.descriptionTextStyle = .footnote
    }

    static var estimatedRowHeight: CGFloat = 50
    static var identifier = "WMFArticleListTableViewCell"
    
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
    
    @objc(setTitleText:highlightingText:)
    func set(titleText: String?, highlightingText: String?) {
        guard let titleText = titleText else {
            self.titleText = nil
            return
        }
        
        let attributedTitle = NSMutableAttributedString(string: titleText, attributes: [NSFontAttributeName: articleCell.titleLabel.font])
        if let highlightingText = highlightingText {
            let range = (titleText as NSString).range(of: highlightingText)
            if !WMFRangeIsNotFoundOrEmpty(range), let boldFont = UIFont.wmf_preferredFontForFontFamily(articleCell.titleFontFamily, withTextStyle: articleCell.titleTextStyle) {
                attributedTitle.addAttributes([NSFontAttributeName: boldFont], range: range)
            }
        }
        articleCell.titleLabel.attributedText = attributedTitle
    }

}

extension ArticleListTableViewCell: Themeable {
    func apply(theme: Theme) {
        articleCell.apply(theme: theme)
    }
}
