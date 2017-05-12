import UIKit

@objc(WMFArticleRightAlignedImageCollectionViewCell)
open class ArticleRightAlignedImageCollectionViewCell: ArticleCollectionViewCell {
    private var kvoButtonTitleContext = 0
    
    override open var imageWidth: Int {
        return traitCollection.wmf_nearbyThumbnailWidth
    }
    
    override open func setup() {
        imageView.cornerRadius = 3
        imageView.masksToBounds = true
        super.setup()
    }
  
    override open func backgroundColor(for displayType: WMFFeedDisplayType) -> UIColor {
        return UIColor.white
    }
    
    override open func isSaveButtonHidden(for displayType: WMFFeedDisplayType) -> Bool {
        return false
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let margins = UIEdgeInsetsMake(20, 13, 5, 13)
        
        var widthMinusMargins = size.width - margins.left - margins.right
        if !isImageViewHidden {
            let imageViewDimension: CGFloat = 70
            let imageViewY = 0.5*size.height - 0.5*imageViewDimension
            imageView.frame = CGRect(x: size.width - margins.right - imageViewDimension, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            widthMinusMargins = widthMinusMargins - 13 - 70
        }
        
        var y: CGFloat = margins.top
        y = layout(for: titleLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        y = layout(for: descriptionLabel, x: margins.left, y: y, width: widthMinusMargins, apply:apply)
        
        if !isSaveButtonHidden {
            y += 10
            y = layout(forView: saveButton, x: margins.left, y: y, width: widthMinusMargins, apply: true)
            y += 10
        }
        y += margins.bottom
        return CGSize(width: size.width, height: y)
    }

}

