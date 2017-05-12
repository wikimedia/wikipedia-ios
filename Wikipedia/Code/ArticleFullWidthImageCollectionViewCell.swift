import UIKit

@objc(WMFArticleFullWidthImageCollectionViewCell)
open class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    override open var imageWidth: Int {
        return traitCollection.wmf_leadImageWidth
    }
    
    override open class var nibName: String {
        return "ArticleFullWidthImageCollectionViewCell"
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.georgia, withTextStyle: .title1, compatibleWithTraitCollection: traitCollection)
    }
}
