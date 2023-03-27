import Foundation
import Combine

enum UpdateState {
    case never
    case updating
    case lastUpdateFailed
    case updated
}

/// Actual locations information state
/// Use it as source of truth about locations
struct LocationsState {
    var locations: [Location] = []
    var updateState: UpdateState = .never
}

/// Update locations and listen for locations updates
protocol LocationsService {
    var locationsState: AnyPublisher<LocationsState, Never> { get }
    func updateLocations()
}

protocol LocationsServiceProvider {
    var locationsService: LocationsService { get }
}

final class LocationsServiceImpl: ObservableObject, LocationsService {
    
    typealias Dependencies = LocationsAPIServiceProvider
    private let dependencies: Dependencies
    
    private var bag: Set<AnyCancellable> = []
    @Published private(set) var locationsStatePublished: LocationsState = .init()
    
    // Expose state publisher to match protocol requirements
    var locationsState: AnyPublisher<LocationsState, Never> { $locationsStatePublished.eraseToAnyPublisher() }
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    /// Update locations from API
    func updateLocations() {
        bag = []
        startUpdating()
        dependencies.locationsAPIService.getLocations()
            .receive(on: DispatchQueue.main)
            .retry(1)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    self.processError()
                case .finished:
                    break
                }
            }, receiveValue: { locationsResponce in
                self.processLocations(locationsResponce.locations)
            })
            .store(in: &bag)
    }
    
    private func startUpdating() {
        var newState = locationsStatePublished
        newState.updateState = .updating
        self.locationsStatePublished = newState
    }
    
    private func processLocations(_ locations: [Location]) {
        var newState = locationsStatePublished
        newState.updateState = .updated
        newState.locations = locations
        self.locationsStatePublished = newState
    }
    
    private func processError() {
        var newState = locationsStatePublished
        newState.updateState = .lastUpdateFailed
        self.locationsStatePublished = newState
    }
}
