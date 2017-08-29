import UIKit

@objc(WMFRankedArticleCollectionViewCell)
public class RankedArticleCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {

    var rankView = CircledRankView(frame: .zero)
    
    override open func setup() {
        addSubview(rankView)
        super.setup()
    }
    
    override open func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        rankView.labelBackgroundColor = labelBackgroundColor
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let headerIconDimension: CGFloat = 40
        let rankViewLeftMargin = ArticleCollectionViewCell.defaultMargins.left
        margins = UIEdgeInsets(top: margins.top, left: 2 * ArticleCollectionViewCell.defaultMargins.left + headerIconDimension, bottom: margins.bottom, right: margins.right)
        let superSize = super.sizeThatFits(size, apply: apply)
        
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        let rankViewWidthPlusPadding =  (2 * rankViewLeftMargin) + headerIconDimension
        let x = isRTL ? size.width - rankViewWidthPlusPadding : 0
        let rankViewFrame = rankView.wmf_preferredFrame(at: CGPoint(x: x, y: margins.top), maximumViewSize: CGSize(width: rankViewWidthPlusPadding, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: rankViewWidthPlusPadding, height: superSize.height - margins.top - margins.bottom), horizontalAlignment: .center, verticalAlignment: .center, apply: apply)
        return CGSize(width: superSize.width, height: max(superSize.height, rankViewFrame.size.height + margins.top + margins.bottom))
    }

}
