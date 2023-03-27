import Foundation
import UIKit

protocol LocationsViewsFactory {
    
    func makeTitle(_ text: String) -> UIView
    func makeInput(location: Location?) -> InputCard
    func makeLocationCard(_ location: Location, index: Int) -> LocationCard
}

final class LocationsViewsFactoryImpl: LocationsViewsFactory {
    
    typealias Dependencies = OpenLocationServiceProvider
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func makeTitle(_ text: String) -> UIView {
        let title = UILabel.title2
        title.text = text
        return title
    }
    
    func makeInput(location: Location?) -> InputCard {
        let presenter = InputCardPresenter(dependencies: dependencies)
        if let location = location, location != .none {
            return InputCard(cardPayload: .init(location: "\(location.lat),\(location.long)"), ID: 0, presenter: presenter)
        }
        return InputCard(cardPayload: .init(location: nil), ID: 0, presenter: presenter)
    }
    
    func makeLocationCard(_ location: Location, index: Int) -> LocationCard {
        LocationCard(
            cardPayload: .init(locationName: location.name, location: "lattitude: \(location.lat), longitude: \(location.long)"),
            ID: index
        )
    }
}
