import UIKit
import CoreLocation

final public class WMFCommonsUploadViewModel {
    let uiImage: UIImage
    let coordinate: CLLocationCoordinate2D

    public init(uiImage: UIImage, coordinate: CLLocationCoordinate2D) {
        self.uiImage = uiImage
        self.coordinate = coordinate
    }
}
