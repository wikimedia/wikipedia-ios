import Foundation

protocol ApplicationDependencies:
    LocationsServiceProvider {}

/// Root of dependency composition
final class MainAssembly: ApplicationDependencies {
    
    lazy var locationsService: LocationsService = LocationsServiceImpl()
}
