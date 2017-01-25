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
    let countLabel: UILabel
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        imageView = UIImageView()
        countLabel = UILabel()
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.wmf_green().withAlphaComponent(0.7)
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        countLabel.textColor = UIColor.white
        countLabel.textAlignment = .center
        countLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        addSubview(countLabel)
        
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
                } else {
                    countLabel.text = "\(articlePlace.articles.count)"
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.wmf_reset()
        countLabel.text = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        imageView.layer.cornerRadius = frame.size.width * 0.5
        countLabel.frame = bounds
    }
}

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    @IBOutlet weak var mapView: MKMapView!
    var searchBar: UISearchBar!
    var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    var annotations: [MKAnnotation] = []
    var articles: [WMFArticle] = []
    var articleStore: WMFArticleDataStore!
    var dataStore: MWKDataStore!
    var segmentedControl: UISegmentedControl!
    
    var currentGroupingPrecision: QuadKeyPrecision = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        //Override UINavigationBar.appearance settings from WMFStyleManager
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = nil
        segmentedControl = UISegmentedControl(items: ["Default", "PageViews", "Links"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        
        mapView.setUserTrackingMode(.follow, animated: true)
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 32))
        navigationItem.titleView = searchBar
        searchBar.delegate = self
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regroupArticlesIfNecessary()
    }
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        
    }
    
    func segmentedControlChanged() {
        redoSearch(self)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let place = view.annotation as? ArticlePlace,
                let article = place.articles.first,
                let url = article.url else {
            return
        }
        wmf_pushArticle(with: url, dataStore: dataStore, previewStore: articleStore, animated: true)
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
            let dimension = (min(mapView.bounds.size.width, mapView.bounds.size.height)/8.0).rounded()
            placeView?.frame = CGRect(x: 0, y: 0, width: dimension, height: dimension)
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
        let center = mapView.region.center
        let mapRect = mapView.visibleMapRect
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(center.latitude)
        let widthInMeters = mapRect.size.width * metersPerMapPoint
        let heightInMeters =  mapRect.size.height * metersPerMapPoint
        let radius = min(widthInMeters, heightInMeters)
        let region = CLCircularRegion(center: center, radius: radius, identifier: "")
        let siteURL = self.siteURL
        var sortStyle = WMFLocationSearchSortStyleNone
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            sortStyle = WMFLocationSearchSortStylePageViews
        case 2:
            sortStyle = WMFLocationSearchSortStyleLinks
        case 0:
            fallthrough
        default:
            break
        }
        nearbyFetcher.fetchArticles(withSiteURL: siteURL, in: region, matchingSearchTerm: searchBar.text, sortStyle: sortStyle, resultLimit: 50, completion: { (searchResults) in
            self.searching = false
            self.updatePlaces(withSearchResults: searchResults.results)
        }) { (error) in
            self.wmf_showAlertWithError(error as NSError)
            self.searching = false
        }
    }

    func regroupArticlesIfNecessary() {
        struct ArticleGroup {
            var articles: [WMFArticle] = []
            var latitudeSum: QuadKeyDegrees = 0
            var longitudeSum: QuadKeyDegrees = 0
        }
        
        let deltaLat = mapView.region.span.latitudeDelta
        let lowestPrecision = QuadKeyPrecision(deltaLatitude: deltaLat)
        let groupingPrecision = min(QuadKeyPrecision.maxPrecision, lowestPrecision + 2)
        
        guard groupingPrecision != currentGroupingPrecision else {
            return
        }
        
        removeAllAnnotations()
        
        var groups: [QuadKey: ArticleGroup] = [:]

        for article in articles {
            guard let quadKey = article.quadKey else {
                continue
            }
            let adjustedQuadKey = quadKey.adjusted(downBy: QuadKeyPrecision.maxPrecision - groupingPrecision)
            var group = groups[adjustedQuadKey] ?? ArticleGroup()
            group.articles.append(article)
            let coordinate = QuadKeyCoordinate(quadKey: quadKey)
            group.latitudeSum += coordinate.latitude
            group.longitudeSum += coordinate.longitude
            groups[adjustedQuadKey] = group
        }
        
        for (_, group) in groups {
            let articles = group.articles
            let count = CLLocationDegrees(articles.count)
            let latitude = CLLocationDegrees(group.latitudeSum)/count
            let longitude = CLLocationDegrees(group.longitudeSum)/count
            guard let place = ArticlePlace(coordinate: CLLocationCoordinate2DMake(latitude, longitude), articles: articles) else {
                continue
            }
            addAnnotation(place)
        }
        
        currentGroupingPrecision = groupingPrecision
    }
    
    func updatePlaces(withSearchResults searchResults: [MWKLocationSearchResult]) {
        for result in searchResults {
            guard let displayTitle = result.displayTitle,
                let articleURL = (siteURL as NSURL).wmf_URL(withTitle: displayTitle),
                let article = self.articleStore?.addPreview(with: articleURL, updatedWith: result),
                let _ = article.quadKey else {
                    continue
            }
            articles.append(article)
        }
        currentGroupingPrecision = 0
        regroupArticlesIfNecessary()
    }
    
    
}

