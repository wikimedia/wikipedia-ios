import Foundation
import Combine
import CoreLocation

protocol LocationsAPIServiceProvider {
    var locationsAPIService: LocationsAPIService { get }
}

protocol LocationsAPIService {
    func getLocations(session: URLSession) -> AnyPublisher<LocationList, any Error>
}

final class LocationsAPIServiceImpl: LocationsAPIService {
    
    func getLocations(session: URLSession) -> AnyPublisher<LocationList, any Error> {
        let request = LocationsEndpoint.locationsList().request!
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: LocationList.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

extension LocationsAPIService {
    func getLocations() -> AnyPublisher<LocationList, any Error> {
        getLocations(session: .shared)
    }
}
