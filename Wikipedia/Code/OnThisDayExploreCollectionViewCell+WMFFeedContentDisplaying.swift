import UIKit

extension OnThisDayExploreCollectionViewCell {
    public func configure(with onThisDayEvent: WMFFeedOnThisDayEvent,  previousEvent: WMFFeedOnThisDayEvent?, dataStore: MWKDataStore, theme: Theme, layoutOnly: Bool) {
        bottomTitleLabel.text = previousEvent?.yearString
        super.configure(with: onThisDayEvent, dataStore: dataStore, showArticles: false, theme: theme, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }
}
