import UIKit
import MapKit

class NearbyViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        mapView.mapType = .standard

        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.showsPointsOfInterest = false
        mapView.showsBuildings = false

        mapView.showsTraffic = false
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        mapView.setUserTrackingMode(.follow, animated: true)
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        
    }
}

