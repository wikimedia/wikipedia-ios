import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell) class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    override open var estimatedHeight: CGFloat {
        return 104
    }
    
    override open var imageWidth: Int {
        return traitCollection.wmf_nearbyThumbnailWidth
    }
}
