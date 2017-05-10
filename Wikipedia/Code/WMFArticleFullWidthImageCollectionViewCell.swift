import UIKit

@objc(WMFArticleFullWidthImageCollectionViewCell) class ArticleFullWidthImageCollectionViewCell: ArticleCollectionViewCell {
    override open var estimatedHeight: CGFloat {
        return 228
    }
    
    override open var imageWidth: Int {
        return traitCollection.wmf_leadImageWidth
    }
}
