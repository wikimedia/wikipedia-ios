import UIKit

@objc(WMFRankedArticleCollectionViewCell)
public class RankedArticleCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {

    var rankView = CircledRankView(frame: .zero)
    
    override open func setup() {
        addSubview(rankView)
        super.setup()
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        var widthMinusMargins = size.width - margins.left - margins.right
        let heightMinusMargins = size.height - margins.top - margins.bottom
        if !isImageViewHidden {
            if (apply) {
                let imageViewY = margins.top + round(0.5*heightMinusMargins - 0.5*imageViewDimension)
                var x =  margins.right
                if !isRTL {
                    x = size.width - x - imageViewDimension
                }
                imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
            }
            widthMinusMargins = widthMinusMargins - margins.right - imageViewDimension
        }
        
        let headerIconDimension: CGFloat = 40
        let rankViewSize = rankView.sizeThatFits(size)
        widthMinusMargins = widthMinusMargins - margins.left - headerIconDimension
        if (apply) {
            let rankViewY = margins.top + round(0.5*heightMinusMargins - 0.5*rankViewSize.height)
            let halfRankViewWidth = round(0.5*rankViewSize.width)
            let dimension = margins.left + 0.5 * headerIconDimension
            var x = dimension - halfRankViewWidth
            if isRTL {
                x = size.width - x - rankViewSize.width
            }
            rankView.frame = CGRect(origin: CGPoint(x: x, y: rankViewY), size: rankViewSize)
        }
        
        var x = margins.left + headerIconDimension + margins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        var origin = CGPoint(x: x, y: margins.top)
        
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: spacing)
        
        let descriptionLabelFrame = descriptionLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
        origin.y += descriptionLabelFrame.layoutHeight(with: spacing)
        
        if !isSaveButtonHidden {
            origin.y += saveButtonTopSpacing
            let saveButtonFrame = saveButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: articleSemanticContentAttribute, apply: apply)
            origin.y += saveButtonFrame.height
        }
        origin.y += margins.bottom
        let totalRankViewHeight = rankViewSize.height + margins.top + margins.bottom
        let height = isImageViewHidden ? max(totalRankViewHeight, origin.y) : max(origin.y, imageViewDimension + margins.top + margins.bottom, totalRankViewHeight)
        return CGSize(width: size.width, height: height)
    }

}
