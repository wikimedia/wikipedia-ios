import UIKit

extension OnThisDayExploreCollectionViewCell {
    @objc(configureWithOnThisDayEvent:previousEvent:dataStore:theme:layoutOnly:)
    public func configure(with onThisDayEvent: WMFFeedOnThisDayEvent,  previousEvent: WMFFeedOnThisDayEvent?, dataStore: MWKDataStore, theme: Theme, layoutOnly: Bool) {
        bottomTitleLabel.text = previousEvent?.yearString
        super.configure(with: onThisDayEvent, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }
}
