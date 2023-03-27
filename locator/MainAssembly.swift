import Foundation

protocol ApplicationDependencies:
    LocationsAPIServiceProvider,
    LocationsServiceProvider {}

/// Root of dependency composition
final class MainAssembly: ApplicationDependencies {
    
    lazy var locationsAPIService: LocationsAPIService = LocationsAPIServiceImpl()
    lazy var locationsService: LocationsService = LocationsServiceImpl(dependencies: self)
}
