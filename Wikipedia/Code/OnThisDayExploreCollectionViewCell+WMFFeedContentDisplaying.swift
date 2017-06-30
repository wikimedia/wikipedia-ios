import UIKit

extension OnThisDayExploreCollectionViewCell {
    @objc(configureWithOnThisDayEvent:previousEvent:dataStore:layoutOnly:)
    func configure(with onThisDayEvent: WMFFeedOnThisDayEvent,  previousEvent: WMFFeedOnThisDayEvent, dataStore: MWKDataStore, layoutOnly: Bool) {
        bottomTitleLabel.textColor = .wmf_blue
        bottomTitleLabel.text = previousEvent.yearWithEraString()
        super.configure(with: onThisDayEvent, dataStore: dataStore, layoutOnly: layoutOnly, shouldAnimateDots: false)
    }
}
