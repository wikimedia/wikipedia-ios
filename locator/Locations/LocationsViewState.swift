import Foundation
import UIKit

enum Section {
    case input
    case locations
}

/// Represents locations screen state as a input and lists of locations
struct LocationsViewState {
    
    let screenTitle = "Explore place"
    let inputTitle = "Custom coordinates"
    let listTitle = "Top list"
    let locations: [Location]
    let updateState: UpdateState
    
    static let initial: Self = .init(locations: [], updateState: .never)
    
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
        if !locations.isEmpty {
            snapshot.appendSections([.locations])
            snapshot.appendItems(locations)
        }
        return snapshot
    }
}
