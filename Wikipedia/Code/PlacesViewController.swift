import UIKit
import MapKit
import WMF

class ArticlePlace: NSObject, MKAnnotation {
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    public let articles: [WMFArticle]
    
    init?(coordinate: CLLocationCoordinate2D, articles: [WMFArticle]) {
        self.title = nil
        self.subtitle = nil
        self.coordinate = coordinate
        self.articles = articles
    }
}

class ArticlePlaceView: MKAnnotationView {
    let imageView: UIImageView
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        imageView = UIImageView()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.wmf_lightBlueTint()
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        addSubview(imageView)
        layoutSubviews()
        self.annotation = annotation
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            if let articlePlace = annotation as? ArticlePlace {
                if articlePlace.articles.count == 1 {
                    let article = articlePlace.articles[0]
                    if let thumbnailURL = article.thumbnailURL  {
                        imageView.wmf_setImage(with: thumbnailURL, detectFaces: true, onGPU: true, failure: { (error) in
                            
                        }, success: {
                            
                        })
                    }
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        imageView.layer.cornerRadius = frame.size.width * 0.5
    }
}

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    @IBOutlet weak var mapView: MKMapView!
    var searchBar: UISearchBar!
    var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    var annotations: [MKAnnotation] = []
    var articleStore: WMFArticleDataStore?

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
        let reuseIdentifier = "org.wikimedia.articlePlaceView"
        guard let place = annotation as? ArticlePlace else {
            return nil
        }
        var placeView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if placeView == nil {
            placeView = ArticlePlaceView(annotation: place, reuseIdentifier: reuseIdentifier)
            placeView?.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        } else {
            placeView?.annotation = place
        }
        
        return placeView
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
        let siteURL = self.siteURL
        nearbyFetcher.fetchArticles(withSiteURL: siteURL, in: region, matchingSearchTerm: searchBar.text, resultLimit: 50, completion: { (searchResults) in
            self.searching = false
            for result in searchResults.results {
                guard let displayTitle = result.displayTitle,
                    let articleURL = (siteURL as NSURL).wmf_URL(withTitle: displayTitle),
                    let article = self.articleStore?.addPreview(with: articleURL, updatedWith: result),
                    let coordinate = article.coordinate,
                    let articlePlace = ArticlePlace(coordinate: coordinate, articles: [article]) else {
                    continue
                }
                self.addAnnotation(articlePlace)
            }
        }) { (error) in
            self.wmf_showAlertWithError(error as NSError)
            self.searching = false
        }
    }
    
    
    
    
}

