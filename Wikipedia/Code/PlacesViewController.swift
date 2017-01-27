import UIKit
import MapKit
import WMF
import TUSafariActivity

enum PlaceSearchType {
    case text
    case location
    case top
    case saved
}

struct PlaceSearch {
    let type: PlaceSearchType
    let string: String?
    let region: CLCircularRegion
}


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
    
    var currentSearch: PlaceSearch? {
        didSet {
            if let search = currentSearch {
                switch search.type {
                case .top:
                    searchBar.text = localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby")
                default:
                    break
                }
                performSearch(search)
            }
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor.wmf_blueTint()
        redoSearchButton.backgroundColor = view.tintColor
        
        //Override UINavigationBar.appearance settings from WMFStyleManager
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = nil
        segmentedControl = UISegmentedControl(items: ["M", "L"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        segmentedControl.tintColor = UIColor.wmf_blueTint()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        
        mapView.showsPointsOfInterest = false
        mapView.setUserTrackingMode(.follow, animated: true)
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 32))
        //searchBar.keyboardType = .webSearch
        searchBar.text = localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby")
        searchBar.returnKeyType = .search
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
        
        let visibleRegion = currentlyVisibleCircularCoordinateRegion
        
        if let search = currentSearch {
            let distance = CLLocation(latitude: visibleRegion.center.latitude, longitude: visibleRegion.center.longitude).distance(from: CLLocation(latitude: search.region.center.latitude, longitude: search.region.center.longitude))
            let radiusRatio = visibleRegion.radius/search.region.radius
            redoSearchButton.isHidden = !(radiusRatio > 1.33 || radiusRatio < 0.67 || distance/search.region.radius > 0.33)
        } else {
            currentSearch = PlaceSearch(type: .top, string: nil, region: visibleRegion)
        }
        
        guard let _ = presentedViewController else {
            return
        }
        dismiss(animated: false, completion: nil)
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
            
            let center = place.coordinate
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
        presentationController.passthroughViews = [mapView]
        
        if let _ = presentedViewController {
            dismiss(animated: false, completion: {
                self.present(articleVC, animated: false) {
                    
                }
            })
        } else {
            present(articleVC, animated: false) {
                
            }
        }

    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let _ = presentedViewController else {
            return
        }
        dismiss(animated: false, completion: nil)
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
    
    var currentlyVisibleCircularCoordinateRegion: CLCircularRegion {
        get {
            let center = mapView.region.center
            let mapRect = mapView.visibleMapRect
            let metersPerMapPoint = MKMetersPerMapPointAtLatitude(center.latitude)
            let widthInMeters = mapRect.size.width * metersPerMapPoint
            let heightInMeters =  mapRect.size.height * metersPerMapPoint
            let radius = min(widthInMeters, heightInMeters)
            return CLCircularRegion(center: center, radius: radius, identifier: "")
        }
    }
    
    func performSearch(_ search: PlaceSearch) {
        guard !searching else {
            return
        }
        searching = true
        
        
        let siteURL = self.siteURL
        
        
        var searchTerm: String? = nil
        var sortStyle = WMFLocationSearchSortStyleNone
        let region = search.region
        
        switch search.type {
        case .top:
            sortStyle = WMFLocationSearchSortStylePageViews
        case .location:
            fallthrough
        case .text:
            fallthrough
        default:
            searchTerm = search.string
        }
        
        nearbyFetcher.fetchArticles(withSiteURL: siteURL, in: region, matchingSearchTerm: searchTerm, sortStyle: sortStyle, resultLimit: 50, completion: { (searchResults) in
            self.searching = false
            self.updatePlaces(withSearchResults: searchResults.results)
        }) { (error) in
            self.wmf_showAlertWithError(error as NSError)
            self.searching = false
        }
    }
    
    @IBAction func redoSearch(_ sender: Any) {
        guard let search = currentSearch else {
            return
        }
        currentSearch = PlaceSearch(type: search.type, string: search.string, region: currentlyVisibleCircularCoordinateRegion)
        redoSearchButton.isHidden = true
    }

    func regroupArticlesIfNecessary() {
        struct ArticleGroup {
            var articles: [WMFArticle] = []
            var latitudeSum: QuadKeyDegrees = 0
            var longitudeSum: QuadKeyDegrees = 0
            
            var location: CLLocation {
                get {
                    return CLLocation(latitude: latitudeSum/CLLocationDegrees(articles.count), longitude: longitudeSum/CLLocationDegrees(articles.count))
                }
            }
        }
        
        let deltaLat = mapView.region.span.latitudeDelta
        let lowestPrecision = QuadKeyPrecision(deltaLatitude: deltaLat)
        let groupingPrecision = min(QuadKeyPrecision.maxPrecision, lowestPrecision + 4)
        
        let groupingDeltaLatitude = groupingPrecision.deltaLatitude
        let groupingDeltaLongitude = groupingPrecision.deltaLongitude
        let groupingDistance = currentlyVisibleCircularCoordinateRegion.radius / 10.0
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
        
        let keys = groups.keys
        
        for quadKey in keys {
            guard var group = groups[quadKey] else {
                continue
            }
            let location = group.location
            for t in -1...1 {
                for n in -1...1 {
                    let adjacentLatitude = location.coordinate.latitude + CLLocationDegrees(t)*groupingDeltaLatitude
                    let adjacentLongitude = location.coordinate.longitude + CLLocationDegrees(n)*groupingDeltaLongitude
                    let adjacentQuadKey = QuadKey(latitude: adjacentLatitude, longitude: adjacentLongitude)
                    let adjustedQuadKey = adjacentQuadKey.adjusted(downBy: QuadKeyPrecision.maxPrecision - groupingPrecision)
                    guard adjustedQuadKey != quadKey, let adjacentGroup = groups[adjustedQuadKey] else {
                        continue
                    }
                    
                    let distance = adjacentGroup.location.distance(from: location)
                    if distance < groupingDistance {
                        group.articles.append(contentsOf: adjacentGroup.articles)
                        group.latitudeSum += adjacentGroup.latitudeSum
                        group.longitudeSum += adjacentGroup.longitudeSum
                        groups.removeValue(forKey: adjustedQuadKey)
                    }
                }
            }
            
            guard let place = ArticlePlace(coordinate: group.location.coordinate, articles: group.articles) else {
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
    
    //UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentSearch = PlaceSearch(type: .text, string: searchBar.text, region: currentlyVisibleCircularCoordinateRegion)
    }
}

