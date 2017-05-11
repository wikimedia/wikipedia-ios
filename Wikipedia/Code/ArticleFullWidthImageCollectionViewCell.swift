import UIKit

@objc(WMFArticleFullWidthImageCollectionViewCell) class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    override open var estimatedHeight: CGFloat {
        return 228
    }
    
    override open var imageWidth: Int {
        return traitCollection.wmf_leadImageWidth
    }
    
    override open class var nibName: String {
        return "ArticleFullWidthImageCollectionViewCell"
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.georgia, withTextStyle: .title1, compatibleWithTraitCollection: traitCollection)
    }
}
