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
        layoutMargins = UIEdgeInsets(top: layoutMargins.top, left: 2 * ArticleCollectionViewCell.defaultMargins.left + headerIconDimension, bottom: layoutMargins.bottom, right: layoutMargins.right)
        let superSize = super.sizeThatFits(size, apply: apply)
        
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        let rankViewWidthPlusPadding =  (2 * rankViewLeftMargin) + headerIconDimension
        let x = isRTL ? size.width - rankViewWidthPlusPadding : 0
        let rankViewFrame = rankView.wmf_preferredFrame(at: CGPoint(x: x, y: layoutMargins.top), maximumViewSize: CGSize(width: rankViewWidthPlusPadding, height: UIViewNoIntrinsicMetric), minimumLayoutAreaSize: CGSize(width: rankViewWidthPlusPadding, height: superSize.height - layoutMargins.top - layoutMargins.bottom), horizontalAlignment: .center, verticalAlignment: .center, apply: apply)
        return CGSize(width: superSize.width, height: max(superSize.height, rankViewFrame.size.height + layoutMargins.top + layoutMargins.bottom))
    }

}
