import UIKit
import MapKit

class ArticleAnnotation: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    
    init?(searchResult: MWKLocationSearchResult) {
        guard let location = searchResult.location else {
            return nil
        }
        coordinate = location.coordinate
        title = searchResult.displayTitle
        subtitle = searchResult.wikidataDescription
    }
}

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    @IBOutlet weak var mapView: MKMapView!
    var searchBar: UISearchBar!
    var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    
    var annotations: [MKAnnotation] = []

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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
    }
    
    func removeAllAnnotations() {
        mapView.removeAnnotations(annotations)
        annotations.removeAll(keepingCapacity: true)
    }
    
    func addAnnotation(_ annotation: MKAnnotation) {
        annotations.append(annotation)
        mapView.addAnnotation(annotation)
    }
    
    var searching: Bool = false {
        didSet {
            
        }
    }
    
    @IBAction func redoSearch(_ sender: Any) {
        guard !searching else {
            return
        }
        searching = true
        removeAllAnnotations()
        let center = mapView.region.center
        let mapRect = mapView.visibleMapRect
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(center.latitude)
        let widthInMeters = mapRect.size.width * metersPerMapPoint
        let heightInMeters =  mapRect.size.height * metersPerMapPoint
        let radius = min(widthInMeters, heightInMeters)
        let region = CLCircularRegion(center: center, radius: radius, identifier: "")
        nearbyFetcher.fetchArticles(withSiteURL: siteURL, in: region, matchingSearchTerm: searchBar.text, resultLimit: 50, completion: { (searchResults) in
            self.searching = false
            for result in searchResults.results {
                guard let annotation = ArticleAnnotation(searchResult: result) else {
                    continue
                }
                self.addAnnotation(annotation)
            }
        }) { (error) in
            self.wmf_showAlertWithError(error as NSError)
            self.searching = false
        }
    }
    
    
    
    
}

