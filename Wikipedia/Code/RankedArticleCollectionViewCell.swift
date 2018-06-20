import UIKit

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
        let rankViewLeftMargin = self.layoutMargins.left
        layoutMarginsAdditions = UIEdgeInsets(top: 0, left: headerIconDimension + rankViewLeftMargin, bottom: 0, right: 0)
        let superSize = super.sizeThatFits(size, apply: apply)
        let layoutMargins = calculatedLayoutMargins
        let isLTR = articleSemanticContentAttribute != .forceRightToLeft
        let x = isLTR ? calculatedLayoutMargins.left - layoutMarginsAdditions.left : size.width - calculatedLayoutMargins.left + layoutMarginsAdditions.left - headerIconDimension
        let maximumHeight = superSize.height - layoutMargins.top  - layoutMargins.bottom
        let maximumWidth = headerIconDimension
        let _ = rankView.wmf_preferredFrame(at: CGPoint(x: x, y: calculatedLayoutMargins.top), maximumSize: CGSize(width: maximumWidth, height: maximumHeight), minimumSize: CGSize(width: headerIconDimension, height: headerIconDimension), horizontalAlignment: .center, verticalAlignment: .center, apply: apply)
        return superSize
    }

}
