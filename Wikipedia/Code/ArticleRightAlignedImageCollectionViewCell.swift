import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {    
    override open var imageWidth: Int {
        return traitCollection.wmf_nearbyThumbnailWidth
    }
    
    override open class var nibName: String {
        return "ArticleRightAlignedImageCollectionViewCell"
    }
}
