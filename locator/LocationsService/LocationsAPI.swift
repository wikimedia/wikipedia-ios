import Foundation
import Combine

struct LocationsEndpoint {
    var path: String
    var queryItems: [URLQueryItem] = []
    var request: URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "raw.githubusercontent.com"
        components.path = path
        components.queryItems = queryItems
        guard let url = components.url else {
            return nil
        }
        return URLRequest(url: url)
    }
}

extension LocationsEndpoint {
    /// returns endpoint for getting locations list for testing
    static func locationsList() -> Self {
        LocationsEndpoint(path: "/abnamrocoesd/assignment-ios/main/locations.json")
    }
}
