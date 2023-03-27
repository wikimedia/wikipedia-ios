import Foundation

final class InputCardPresenter {
    
    typealias Dependencies = OpenLocationServiceProvider
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func handleLocation(_ locationString: String?) {
        // TODO: error handling
        let errorHandler = {
            print("Invalid location string")
        }
        
        guard let components = locationString?.split(separator: ","), components.count == 2 else {
            errorHandler()
            return
        }
        guard let latitude = Double(components[0]), let longitude = Double(components[1]) else {
            errorHandler()
            return
        }

        let location = Location(name: nil, lat: latitude, long: longitude)
        dependencies.openLocationService.open(location: location)
    }
}
