import UIKit

extension OnThisDayExploreCollectionViewCell {
    public func configure(with onThisDayEvent: WMFFeedOnThisDayEvent, isFirst: Bool, isLast: Bool, dataStore: MWKDataStore, theme: Theme, layoutOnly: Bool) {
        self.isFirst = isFirst
        self.isLast = isLast
        timelineView.minimizeUnanimatedDots = !isFirst
        super.configure(with: onThisDayEvent, dataStore: dataStore, showArticles: false, theme: theme, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }
}
