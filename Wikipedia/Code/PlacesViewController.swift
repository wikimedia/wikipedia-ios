import UIKit
import MapKit

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    @IBOutlet weak var mapView: MKMapView!
    var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        //Override UINavigationBar.appearance settings from WMFStyleManager
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = nil
        
        mapView.setUserTrackingMode(.follow, animated: true)
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 32))
        navigationItem.titleView = searchBar
        searchBar.delegate = self
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        
    }
    
    @IBAction func redoSearch(_ sender: Any) {
        
    }
    
    
}

