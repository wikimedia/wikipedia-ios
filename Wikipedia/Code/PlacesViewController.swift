import UIKit
import MapKit
import WMF
import TUSafariActivity

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, ArticlePopoverViewControllerDelegate {

    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    @IBOutlet weak var mapView: MKMapView!
    var searchBar: UISearchBar!
    var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    var articles: [WMFArticle] = []
    var articleStore: WMFArticleDataStore!
    var dataStore: MWKDataStore!
    var segmentedControl: UISegmentedControl!
    
    var currentGroupingPrecision: QuadKeyPrecision = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor.wmf_blueTint()
        //Override UINavigationBar.appearance settings from WMFStyleManager
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = nil
        segmentedControl = UISegmentedControl(items: ["Default", "PageViews", "Links"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        segmentedControl.tintColor = UIColor.wmf_blueTint()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        
        mapView.showsPointsOfInterest = false
        mapView.setUserTrackingMode(.follow, animated: true)
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 32))
        navigationItem.titleView = searchBar
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectAllAnnotations()
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regroupArticlesIfNecessary()
    }
    
    func segmentedControlChanged() {
        redoSearch(self)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let place = view.annotation as? ArticlePlace else {
            return
        }
        
        guard place.articles.count == 1 else {
            var latitudeMin = CLLocationDegrees(90)
            var longitudeMin = CLLocationDegrees(180)
            var latitudeMax = CLLocationDegrees(-90)
            var longitudeMax = CLLocationDegrees(-180)
            for article in place.articles {
                guard let coordinate = article.coordinate else {
                    continue
                }
                latitudeMin = min(latitudeMin, coordinate.latitude)
                longitudeMin = min(longitudeMin, coordinate.longitude)
                latitudeMax = max(latitudeMax, coordinate.latitude)
                longitudeMax = max(longitudeMax, coordinate.longitude)
            }
            
            //TODO: handle the wrap condition
            let latitudeDelta = 1.3*(latitudeMax - latitudeMin)
            let longitudeDelta = 1.3*(longitudeMax - longitudeMin)
            
            let center = place.averageArticleCoordinate
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            let region = MKCoordinateRegionMake(center , span)
            mapView.setRegion(region, animated: true)
            return
        }
        
        guard let article = place.articles.first,
            let url = article.url,
            let coordinate = article.coordinate else {
                return
        }
        
        let articleVC = ArticlePopoverViewController()
        articleVC.delegate = self
        articleVC.view.tintColor = view.tintColor
        
        articleVC.article = article
        articleVC.titleLabel.text = article.displayTitle
        articleVC.subtitleLabel.text = article.wikidataDescription
        
        let articleLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let userCoordinate = mapView.userLocation.coordinate
        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        
        let distance = articleLocation.distance(from: userLocation)
        let distanceString = MKDistanceFormatter().string(fromDistance: distance)
        articleVC.descriptionLabel.text = distanceString
        
        articleVC.preferredContentSize = articleVC.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        
        articleVC.edgesForExtendedLayout = []
        articleVC.modalPresentationStyle = .popover
        guard let presentationController = articleVC.popoverPresentationController else {
            wmf_pushArticle(with: url, dataStore: dataStore, previewStore: articleStore, animated: true)
            return
        }
        
        presentationController.sourceView = view
        presentationController.sourceRect = view.bounds
        presentationController.canOverlapSourceViewRect = false
        presentationController.permittedArrowDirections = .any
        presentationController.delegate = self
        
        present(articleVC, animated: true) { 
            
        }
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
        } else {
            placeView?.annotation = place
        }
        
        return placeView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
    }
    
    func deselectAllAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    func removeAllAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    func addAnnotation(_ annotation: MKAnnotation) {
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
        let groupingPrecision = min(QuadKeyPrecision.maxPrecision, lowestPrecision + 4)
        
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
        
        for (quadKey, group) in groups {
            let articles = group.articles
            let count = CLLocationDegrees(articles.count)
            let averageLatitude = CLLocationDegrees(group.latitudeSum)/count
            let averageLongitude = CLLocationDegrees(group.longitudeSum)/count
            var latitude = averageLatitude
            var longitude = averageLongitude
            if articles.count > 1 {
                //cheat coordinate towards the center of the quadKey
                let quadKeyCoordinate = QuadKeyCoordinate(quadKey: quadKey, precision: groupingPrecision)
                latitude = 0.5 * (latitude + quadKeyCoordinate.centerLatitude)
                longitude = 0.5 * (longitude + quadKeyCoordinate.centerLongitude)
            }
            guard let place = ArticlePlace(coordinate: CLLocationCoordinate2DMake(latitude, longitude), averageArticleCoordinate: CLLocationCoordinate2DMake(averageLatitude, averageLongitude), quadKey: quadKey, precision: groupingPrecision, articles: articles) else {
                continue
            }
            addAnnotation(place)
        }
        
        currentGroupingPrecision = groupingPrecision
    }
    
    func updatePlaces(withSearchResults searchResults: [MWKLocationSearchResult]) {
        articles.removeAll(keepingCapacity: true)
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
    
    
    // UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        deselectAllAnnotations()
        return true
    }
    
    // ArticlePopoverViewControllerDelegate
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction: ArticlePopoverViewControllerAction) {
        dismiss(animated: true, completion: {
            
        })
        
        guard let article = articlePopoverViewController.article, let url = article.url else {
            return
        }

        switch didSelectAction {
        case .read:
            wmf_pushArticle(with: url, dataStore: dataStore, previewStore: articleStore, animated: true)
            break
        case .save:
            dataStore.savedPageList.toggleSavedPage(for: url)
            break
        case .share:
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: [TUSafariActivity()])
            present(activityVC, animated: true, completion: nil)
            break
        case .none:
            fallthrough
        default:
            break
        }

    }
}

