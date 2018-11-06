import UIKit

public class RankedArticleCollectionViewCell: ArticleRightAlignedImageCollectionViewCell {

    var rankView = CircledRankView(frame: .zero)
    
    override open func setup() {
        addSubview(rankView)
        super.setup()
    }
    
    let minimumRankDimension: CGFloat = 22

    override open func updateBackgroundColorOfLabels() {
        super.updateBackgroundColorOfLabels()
        rankView.labelBackgroundColor = labelBackgroundColor
    }
    
    override open func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        layoutMarginsAdditions = UIEdgeInsets(top: 0, left: minimumRankDimension + self.layoutMargins.left, bottom: 0, right: 0)
        let superSize = super.sizeThatFits(size, apply: apply)
        let isLTR = articleSemanticContentAttribute != .forceRightToLeft
        let layoutMargins = calculatedLayoutMargins
        let x = isLTR ? layoutMargins.left - layoutMarginsAdditions.left : size.width - layoutMargins.left + layoutMarginsAdditions.left - minimumRankDimension
        let maximumHeight = superSize.height - layoutMargins.top  - layoutMargins.bottom
        let maximumWidth = minimumRankDimension
        let _ = rankView.wmf_preferredFrame(at: CGPoint(x: x, y: layoutMargins.top), maximumSize: CGSize(width: maximumWidth, height: maximumHeight), minimumSize: CGSize(width: minimumRankDimension, height: minimumRankDimension), horizontalAlignment: isLTR ? .right : .right, verticalAlignment: .center, apply: apply)
        return superSize
    }

}

public class RankedArticleExploreCollectionViewCell: RankedArticleCollectionViewCell {
    override open func apply(theme: Theme) {
        super.apply(theme: theme)
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
    }
}
