import Foundation
import UIKit

enum Section {
    case input
    case locations
}

/// Represents locations screen state as a input and lists of locations
struct LocationsViewState {
    internal init(locations: [Location], selectedLocation: Location? = nil, updateState: UpdateState) {
        self.locations = locations
        self.selectedLocation = selectedLocation
        self.updateState = updateState
    }
    
    
    let screenTitle = "Explore place"
    let inputTitle = "Custom coordinates"
    let listTitle = "Top list"
    let locations: [Location]
    private let selectedLocation: Location?
    let updateState: UpdateState
    
    var inputLocation: Location {
        selectedLocation.map { Location(name: "input", lat: $0.lat, long: $0.long) } ?? .none
    }
    
    static let initial: Self = .init(locations: [], selectedLocation: nil, updateState: .never)
    
    var isEmpty: Bool {
        locations.isEmpty && updateState == .updated
    }
    
    func locationFor(section: Section, row: Int) -> Location? {
        switch section {
        case .input:
            return nil
        case .locations:
            return row < locations.endIndex ? locations[row] : nil
        }
    }
    
    func titleFor(section: Section) -> String {
        switch section {
        case .input:
            return inputTitle
        case .locations:
            return listTitle
        }
    }
    
    var snapshot: NSDiffableDataSourceSnapshot<Section, Location> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Location>()
        snapshot.appendSections([.input])
        snapshot.appendItems([inputLocation])
        if !locations.isEmpty {
            snapshot.appendSections([.locations])
            snapshot.appendItems(locations)
        }
        return snapshot
    }
    
    func changingSelectedLocation(_ location: Location) -> Self {
        .init(locations: locations, selectedLocation: location, updateState: updateState)
    }
}
