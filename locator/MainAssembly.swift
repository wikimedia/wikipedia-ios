import Foundation

protocol ApplicationDependencies:
    LocationsAPIServiceProvider,
    LocationsServiceProvider,
    OpenLocationServiceProvider {}

/// Root of dependency composition
final class MainAssembly: ApplicationDependencies {
    
    lazy var locationsAPIService: LocationsAPIService = LocationsAPIServiceImpl()
    lazy var locationsService: LocationsService = LocationsServiceImpl(dependencies: self)
    lazy var openLocationService: OpenLocationService = OpenLocationServiceImpl()
}
