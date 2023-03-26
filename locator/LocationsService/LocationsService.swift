import Foundation
import Combine
import CoreLocation

protocol LocationsService {
    func getLocations(session: URLSession) -> AnyPublisher<LocationList, any Error>
}

final class LocationsServiceImpl: LocationsService {
    
    func getLocations(session: URLSession = .shared) -> AnyPublisher<LocationList, any Error> {
        let request = LocationsEndpoint.locationsList().request!
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: LocationList.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
