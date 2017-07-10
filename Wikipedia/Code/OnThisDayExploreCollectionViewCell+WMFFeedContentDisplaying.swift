import UIKit

extension OnThisDayExploreCollectionViewCell {
    @objc(configureWithOnThisDayEvent:previousEvent:dataStore:theme:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent,  previousEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, theme: Theme, layoutOnly: Bool) {
        bottomTitleLabel.text = previousEvent.yearWithEraString
        super.configure(with: onThisDayEvent, dataStore: dataStore, theme: theme, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }
}
