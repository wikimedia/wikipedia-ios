import UIKit
import WMFComponents
import CoreLocation

final public class CommonsUploadCoordinator: Coordinator {

    var navigationController: UINavigationController
    let image: UIImage
    let coordinate: CLLocationCoordinate2D

    init(navigationController: UINavigationController, image: UIImage, coordinate: CLLocationCoordinate2D) {
        self.navigationController = navigationController
        self.image = image
        self.coordinate = coordinate
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFCommonsUploadViewModel(uiImage: image, coordinate: coordinate)
        let viewController = WMFComonsUploadViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

}
