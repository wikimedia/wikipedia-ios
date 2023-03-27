import Foundation
import UIKit

protocol LocationsViewsFactory {
    
    func makeTitle(_ text: String) -> UIView
    func makeLocationCard(_ location: Location, index: Int) -> LocationCard
}

final class LocationsViewsFactoryImpl: LocationsViewsFactory {
    
    func makeTitle(_ text: String) -> UIView {
        let title = UILabel.title2
        title.text = text
        return title
    }
    
    func makeLocationCard(_ location: Location, index: Int) -> LocationCard {
        return LocationCard(
            cardPayload: .init(locationName: location.name, location: "lattitude: \(location.lat), longitude: \(location.long)"),
            ID: index
        )
    }
}
