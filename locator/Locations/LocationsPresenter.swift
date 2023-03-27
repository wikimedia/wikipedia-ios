import Foundation
import UIKit
import Combine

enum LocationsPresenterOutput {
    case select(location: Location)
}

protocol LocationsPresenter {
    // state for view updates
    var state: CurrentValueSubject<LocationsViewState, Never> { get }
    
    // view actions
    func retry()
    func select(location: Location)
}

final class LocationsPresenterImpl: LocationsPresenter, OpenLocationServiceProvider, OpenLocationService {
    typealias Dependencies = LocationsServiceProvider
    private let dependencies: Dependencies
    
    private var bag: Set<AnyCancellable> = []
    var state: CurrentValueSubject = CurrentValueSubject<LocationsViewState, Never>(.initial)
    var output: (LocationsPresenterOutput) -> Void
    
    init(_ dependencies: Dependencies, output: @escaping (LocationsPresenterOutput) -> Void) {
        self.output = output
        self.dependencies = dependencies
        
        dependencies.locationsService.locationsState.sink { [weak self] state in
            let viewState = LocationsViewState(locations: state.locations, selectedLocation: nil, updateState: state.updateState)
            self?.state.send(viewState)
        }.store(in: &bag)
        
        dependencies.locationsService.updateLocations()
    }
    
    func retry() {
        dependencies.locationsService.updateLocations()
    }
    
    func select(location: Location) {
        self.output(.select(location: location))
        state.send(state.value.changingSelectedLocation(location))
    }
    
    // MARK: - OpenLocationService
    var openLocationService: OpenLocationService { self }
    
    func open(location: Location) {
        select(location: location)
    }
}
