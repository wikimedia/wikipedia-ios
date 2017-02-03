import UIKit
import MapKit
import WMF
import TUSafariActivity

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, ArticlePopoverViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate, PlaceSearchSuggestionControllerDelegate, WMFLocationManagerDelegate {
    
    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    let previewFetcher = WMFArticlePreviewFetcher()
    var localSearch: MKLocalSearch?
    let localCompleter = MKLocalSearchCompleter()
    let globalCompleter = MKLocalSearchCompleter()
    
    let locationManager = WMFLocationManager.coarse()
    
    let animationDuration = 0.6
    let animationScale = CGFloat(0.6)
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var listView: UITableView!
    @IBOutlet weak var searchSuggestionView: UITableView!
    
    var searchSuggestionController: PlaceSearchSuggestionController!
    
    var searchBar: UISearchBar!
    var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    var articles: [WMFArticle] = []
    var articleStore: WMFArticleDataStore!
    var dataStore: MWKDataStore!
    var segmentedControl: UISegmentedControl!
    
    var currentGroupingPrecision: QuadKeyPrecision = 1
    
    let searchHistoryGroup = "PlaceSearch"
    
    var maxGroupingPrecision: QuadKeyPrecision = 17
    var groupingPrecisionDelta: QuadKeyPrecision = 4
    var groupingAggressiveness: CLLocationDistance = 1.0
    
    var currentArticlePopover: ArticlePopoverViewController?
    
    var currentSearch: PlaceSearch? {
        didSet {
            if let search = currentSearch {
                searchBar.text = search.localizedDescription
                performSearch(search)
                switch search.type {
                case .saved:
                    break
                case .top:
                    break
                default:
                    guard search.searchCompletion == nil else {
                        break
                    }
                    saveToHistory(search: search)
                }
            }
        }
    }
    
    func keyValue(forPlaceSearch placeSearch: PlaceSearch, inManagedObjectContext moc: NSManagedObjectContext) -> WMFKeyValue? {
        var keyValue: WMFKeyValue?
        do {
            let key = placeSearch.key
            let request = WMFKeyValue.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@ && group == %@", key, searchHistoryGroup)
            request.fetchLimit = 1
            let results = try moc.fetch(request)
            keyValue = results.first
        } catch let error {
            DDLogError("Error fetching place search key value: \(error.localizedDescription)")
        }
        return keyValue
    }
    
    func saveToHistory(search: PlaceSearch) {
        do {
            let moc = dataStore.viewContext
            if let keyValue = keyValue(forPlaceSearch: search, inManagedObjectContext: moc) {
                keyValue.date = Date()
            } else if let entity = NSEntityDescription.entity(forEntityName: "WMFKeyValue", in: moc) {
                let keyValue =  WMFKeyValue(entity: entity, insertInto: moc)
                keyValue.key = search.key
                keyValue.group = searchHistoryGroup
                keyValue.date = Date()
                keyValue.value = search.dictionaryValue as NSObject
            }
            try moc.save()
        } catch let error {
            DDLogError("error saving to place search history: \(error.localizedDescription)")
        }
    }
    
    func clearSearchHistory() {
        do {
            let moc = dataStore.viewContext
            let request = WMFKeyValue.fetchRequest()
            request.predicate = NSPredicate(format: "group == %@", searchHistoryGroup)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            let results = try moc.fetch(request)
            for result in results {
                moc.delete(result)
            }
            try moc.save()
        } catch let error {
            DDLogError("Error clearing recent place searches: \(error)")
        }
    }
    
    var _mapRegion: MKCoordinateRegion?
    
    var mapRegion: MKCoordinateRegion? {
        set {
            guard let value = newValue else {
                _mapRegion = nil
                return
            }
            
            let region = mapView.regionThatFits(value)
            
            _mapRegion = region
            regroupArticlesIfNecessary(forVisibleRegion: region)
            showRedoSearchButtonIfNecessary(forVisibleRegion: region)
            localCompleter.region = region
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.mapView.region = region
            }) { (finished) in
                
            }
        }
        
        get {
            return _mapRegion
        }
    }
    
    var currentSearchRegion: MKCoordinateRegion?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup map view
        mapView.mapType = .standard
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsPointsOfInterest = false
        mapView.showsScale = true
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.startMonitoringLocation()
        
        //Override UINavigationBar.appearance settings from WMFStyleManager
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = nil
        view.tintColor = UIColor.wmf_blueTint()
        redoSearchButton.backgroundColor = view.tintColor
        
        // Setup map/list toggle
        if let map = UIImage(named: "places-map"), let list = UIImage(named: "places-list") {
            segmentedControl = UISegmentedControl(items: [map, list])
        } else {
            segmentedControl = UISegmentedControl(items: ["M", "L"])
        }

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        segmentedControl.tintColor = UIColor.wmf_blueTint()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        
        // Setup list view
        listView.dataSource = self
        listView.delegate = self
        listView.register(WMFNearbyArticleTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFNearbyArticleTableViewCell.identifier())
        listView.estimatedRowHeight = WMFNearbyArticleTableViewCell.estimatedRowHeight()
        
        // Setup search bar
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 32))
        //searchBar.keyboardType = .webSearch
        searchBar.text = localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby")
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        
        // Setup search suggestions
        searchSuggestionController = PlaceSearchSuggestionController()
        searchSuggestionController.tableView = searchSuggestionView
        searchSuggestionController.delegate = self
        
        // Setup search completers
        localCompleter.filterType = .locationsOnly
        localCompleter.delegate = self
        globalCompleter.filterType = .locationsOnly
        globalCompleter.delegate = self
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectAllAnnotations()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardChanged(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let frameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let frame = frameValue.cgRectValue
        var inset = searchSuggestionView.contentInset
        inset.bottom = frame.size.height
        searchSuggestionView.contentInset = inset
    }
    
    func showRedoSearchButtonIfNecessary(forVisibleRegion visibleRegion: MKCoordinateRegion) {
        guard let searchRegion = currentSearchRegion, let search = currentSearch, search.type != .location, search.type != .saved else {
            redoSearchButton.isHidden = true
            return
        }
        let searchWidth = searchRegion.width
        let searchHeight = searchRegion.height
        let searchRegionMinDimension = min(searchWidth, searchHeight)
        
        let visibleWidth = visibleRegion.width
        let visibleHeight = visibleRegion.height

        let distance = CLLocation(latitude: visibleRegion.center.latitude, longitude: visibleRegion.center.longitude).distance(from: CLLocation(latitude: searchRegion.center.latitude, longitude: searchRegion.center.longitude))
        let widthRatio = visibleWidth/searchWidth
        let heightRatio = visibleHeight/searchHeight
        let ratio = min(widthRatio, heightRatio)
        redoSearchButton.isHidden = !(ratio > 1.33 || ratio < 0.67 || distance/searchRegionMinDimension > 0.33)
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        deselectAllAnnotations()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        _mapRegion = mapView.region
        regroupArticlesIfNecessary(forVisibleRegion: mapView.region)
        showRedoSearchButtonIfNecessary(forVisibleRegion: mapView.region)
        localCompleter.region = mapView.region
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard !listView.isHidden, let indexPaths = listView.indexPathsForVisibleRows else {
            return
        }
        listView.reloadRows(at: indexPaths, with: .none)
    }
    
    func segmentedControlChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            listView.isHidden = true
        default:
            deselectAllAnnotations()
            listView.isHidden = false
            listView.reloadData()
        }
    }
    
    func regionThatFits(_ articles: [WMFArticle]) -> MKCoordinateRegion {
        guard articles.count > 0 else {
            return MKCoordinateRegion()
        }
        var latitudeMin = CLLocationDegrees(90)
        var longitudeMin = CLLocationDegrees(180)
        var latitudeMax = CLLocationDegrees(-90)
        var longitudeMax = CLLocationDegrees(-180)
        
        var longitudeSum = CLLocationDegrees(0)
        var latitudeSum = CLLocationDegrees(0)
        
        for article in articles {
            guard let coordinate = article.coordinate else {
                continue
            }
            latitudeMin = min(latitudeMin, coordinate.latitude)
            longitudeMin = min(longitudeMin, coordinate.longitude)
            latitudeMax = max(latitudeMax, coordinate.latitude)
            longitudeMax = max(longitudeMax, coordinate.longitude)
            
            latitudeSum += coordinate.latitude
            longitudeSum += coordinate.longitude
        }
        
        //TODO: handle the wrap condition
        let latitudeDelta = 1.3*(latitudeMax - latitudeMin)
        let longitudeDelta = 1.3*(longitudeMax - longitudeMin)
        
        let averageLatitude = latitudeSum/CLLocationDegrees(articles.count)
        let averageLongitude = longitudeSum/CLLocationDegrees(articles.count)
        
        let center = CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude)
        let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
        return MKCoordinateRegionMake(center , span)
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotationView: MKAnnotationView) {
        guard let place = annotationView.annotation as? ArticlePlace else {
            return
        }
        
        guard place.articles.count == 1 else {
            mapRegion = regionThatFits(place.articles)
            return
        }
        
        guard let article = place.articles.first,
            let coordinate = article.coordinate else {
                return
        }
        
        guard currentArticlePopover == nil else {
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
        
        let size = articleVC.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        articleVC.preferredContentSize =  size
        articleVC.edgesForExtendedLayout = []
        
        let annotationCenter = view.convert(annotationView.center, from: mapView)
        let center = CGPoint(x: view.bounds.midX, y:  view.bounds.midY)
        let deltaX = annotationCenter.x - center.x
        let deltaY = annotationCenter.y - center.y
        
        let thresholdX = 0.5*(abs(view.bounds.width - size.width))
        let thresholdY = 0.5*(abs(view.bounds.height - size.height))
        
        
        var offsetX: CGFloat
        var offsetY: CGFloat
        
        if abs(deltaX) <= thresholdX {
            offsetX = -0.5 * size.width
            offsetY = deltaY > 0 ?  0 - 30 - size.height : 30
        } else if abs(deltaY) <= thresholdY {
            offsetX = deltaX > 0 ? 0 - 30 - size.width : 30
            offsetY = -0.5 * size.height
        } else {
            offsetX = deltaX > 0 ? 0 - 30 - size.width : 30
            offsetY = deltaY > 0 ?  0 - 30 - size.height : 30
        }
        
        articleVC.view.frame = CGRect(origin: CGPoint(x: annotationCenter.x + offsetX, y: annotationCenter.y + offsetY), size: articleVC.preferredContentSize)
        
        addChildViewController(articleVC)
        view.addSubview(articleVC.view)
        articleVC.didMove(toParentViewController: self)
        currentArticlePopover = articleVC
    }
    
    func dismissCurrentArticlePopover() {
        guard let popover = currentArticlePopover else {
            return
        }
        
        popover.willMove(toParentViewController: nil)
        popover.view.removeFromSuperview()
        popover.removeFromParentViewController()
        currentArticlePopover = nil
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        dismissCurrentArticlePopover()
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
        
        if place.articles.count > 1 && place.nextCoordinate == nil {
            placeView?.alpha = 0
            placeView?.transform = CGAffineTransform(scaleX: animationScale, y: animationScale)
            dispatchOnMainQueue({
                UIView.animate(withDuration: self.animationDuration, animations: {
                    placeView?.transform = CGAffineTransform.identity
                    placeView?.alpha = 1
                })
            })
        } else if let nextCoordinate = place.nextCoordinate {
            placeView?.alpha = 0
            dispatchOnMainQueue({
                UIView.animate(withDuration: self.animationDuration, animations: {
                    place.coordinate = nextCoordinate
                    placeView?.alpha = 1
                })
            })
        } else {
            placeView?.alpha = 0
            dispatchOnMainQueue({
                UIView.animate(withDuration: self.animationDuration, animations: {
                    placeView?.alpha = 1
                })
            })
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
    
    var searching: Bool = false

    
    func performSearch(_ search: PlaceSearch) {
        guard !searching else {
            return
        }
        searching = true
        redoSearchButton.isHidden = true
        
        let siteURL = self.siteURL
        
        
        var searchTerm: String? = nil
        let sortStyle = search.sortStyle
        let region = search.region ?? mapRegion ?? mapView.region
        currentSearchRegion = region
        
        switch search.type {
        case .saved:
            let moc = dataStore.viewContext
            let done = { (articlesToShow: [WMFArticle]) -> Void in
                self.articles = articlesToShow
                self.mapRegion = self.regionThatFits(articlesToShow)
                self.searching = false
                self.updatePlaces()
                
                if articlesToShow.count == 0 {
                    self.wmf_showAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("places-no-saved-articles-have-location"))
                }
            }

            do {
                let savedPagesWithLocation = try moc.fetch(fetchRequestForSavedArticlesWithLocation)
                guard savedPagesWithLocation.count >= 100 else {
                    let savedPagesWithoutLocationRequest = WMFArticle.fetchRequest()
                    savedPagesWithoutLocationRequest.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey == NULL")
                    savedPagesWithoutLocationRequest.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
                    savedPagesWithoutLocationRequest.propertiesToFetch = ["key"]
                    let savedPagesWithoutLocation = try moc.fetch(savedPagesWithoutLocationRequest)
                    guard savedPagesWithoutLocation.count > 0 else {
                        done(savedPagesWithLocation)
                        return
                    }
                    let urls = savedPagesWithoutLocation.flatMap({ (article) -> URL? in
                        return article.url
                    })

                    previewFetcher.fetchArticlePreviewResults(forArticleURLs: urls, siteURL: siteURL, completion: { (searchResults) in
                        var resultsByKey: [String: MWKSearchResult] = [:]
                        for searchResult in searchResults {
                            guard let title = searchResult.displayTitle, searchResult.location != nil else {
                                continue
                            }
                            guard let url = (self.siteURL as NSURL).wmf_URL(withTitle: title)  else {
                                continue
                            }
                            guard let key = (url as NSURL).wmf_articleDatabaseKey else {
                                continue
                            }
                            resultsByKey[key] = searchResult
                        }
                        guard resultsByKey.count > 0 else {
                            done(savedPagesWithLocation)
                            return
                        }
                        let articlesToUpdateFetchRequest = WMFArticle.fetchRequest()
                        articlesToUpdateFetchRequest.predicate = NSPredicate(format: "key IN %@", Array(resultsByKey.keys))
                        do {
                            var allArticlesWithLocation = savedPagesWithLocation
                            let articlesToUpdate = try moc.fetch(articlesToUpdateFetchRequest)
                            for articleToUpdate in articlesToUpdate {
                                guard let key = articleToUpdate.key,
                                    let result = resultsByKey[key] else {
                                    continue
                                }
                                self.articleStore.updatePreview(articleToUpdate, with: result)
                                allArticlesWithLocation.append(articleToUpdate)
                            }
                            try moc.save()
                            done(allArticlesWithLocation)
                        } catch let error {
                            DDLogError("Error fetching saved articles: \(error.localizedDescription)")
                            done(savedPagesWithLocation)
                        }
                    }, failure: { (error) in
                        DDLogError("Error fetching saved articles: \(error.localizedDescription)")
                        done(savedPagesWithLocation)
                    })
                    return
                }
            } catch let error {
                DDLogError("Error fetching saved articles: \(error.localizedDescription)")
            }
            done([])
            return
        case .top:
            break
        case .location:
            guard let completion = search.searchCompletion else {
                if let region = search.region {
                    mapRegion = region
                }
                fallthrough
            }
            let request = MKLocalSearchRequest(completion: completion)
            localSearch = MKLocalSearch(request: request)
            localSearch?.start(completionHandler: { (response, error) in
                guard let response = response else {
                    DDLogError("local search error \(error)")
                    self.searching = false
                    return
                }
                let region = response.boundingRegion
                dispatchOnMainQueue({
                    self.searching = false
                    self.currentSearch = PlaceSearch(type: search.type, sortStyle: search.sortStyle, string: nil, region: region, localizedDescription: search.localizedDescription, searchCompletion: nil)
                })
            })
            return
        case .text:
            fallthrough
        default:
            searchTerm = search.string
        }
        
        let center = region.center
        let halfLatitudeDelta = region.span.latitudeDelta * 0.5
        let halfLongitudeDelta = region.span.longitudeDelta * 0.5
        let top = CLLocation(latitude: center.latitude + halfLatitudeDelta, longitude: center.longitude)
        let bottom = CLLocation(latitude: center.latitude - halfLatitudeDelta, longitude: center.longitude)
        let left =  CLLocation(latitude: center.latitude, longitude: center.longitude - halfLongitudeDelta)
        let right =  CLLocation(latitude: center.latitude, longitude: center.longitude + halfLongitudeDelta)
        let height = top.distance(from: bottom)
        let width = right.distance(from: left)
        
        let radius = round(0.25*(width + height))
        let searchRegion = CLCircularRegion(center: center, radius: radius, identifier: "")
        
        nearbyFetcher.fetchArticles(withSiteURL: siteURL, in: searchRegion, matchingSearchTerm: searchTerm, sortStyle: sortStyle, resultLimit: 50, completion: { (searchResults) in
            self.searching = false
            self.updatePlaces(withSearchResults: searchResults.results)
        }) { (error) in
            self.wmf_showAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("empty-no-search-results-message"))
            self.searching = false
        }
    }
    
    @IBAction func redoSearch(_ sender: Any) {
        guard let search = currentSearch else {
            return
        }
        currentSearch = PlaceSearch(type: search.type, sortStyle: search.sortStyle, string: search.string, region: nil, localizedDescription: search.localizedDescription, searchCompletion: search.searchCompletion)
        redoSearchButton.isHidden = true
    }
    
    var groupingTaskGroup: WMFTaskGroup?
    var needsRegroup = false
    
    func regroupArticlesIfNecessary(forVisibleRegion visibleRegion: MKCoordinateRegion) {
        guard groupingTaskGroup == nil else {
            needsRegroup = true
            return
        }
        assert(Thread.isMainThread)
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
        
        let deltaLon = visibleRegion.span.longitudeDelta
        let lowestPrecision = QuadKeyPrecision(deltaLongitude: deltaLon)
        let maxPrecision: QuadKeyPrecision = maxGroupingPrecision
        let groupingPrecision = min(maxPrecision, lowestPrecision + groupingPrecisionDelta)
        
        guard groupingPrecision != currentGroupingPrecision else {
            return
        }
        
        guard let searchRegion = currentSearchRegion else {
            return
        }
        
        let taskGroup = WMFTaskGroup()
        groupingTaskGroup = taskGroup

        let groupingDeltaLatitude = groupingPrecision.deltaLatitude
        let groupingDeltaLongitude = groupingPrecision.deltaLongitude
        
        let centerLat = searchRegion.center.latitude
        let centerLon = searchRegion.center.longitude
        let groupingDistanceLocation = CLLocation(latitude:centerLat + groupingDeltaLatitude, longitude: centerLon + groupingDeltaLongitude)
        let centerLocation = CLLocation(latitude:centerLat, longitude: centerLon)
        let groupingDistance = groupingAggressiveness * groupingDistanceLocation.distance(from: centerLocation)
        
        var previousPlaceByArticle: [String: ArticlePlace] = [:]
      
        var annotationsToRemove: [String:ArticlePlace] = [:]
        
        for annotation in mapView.annotations {
            guard let place = annotation as? ArticlePlace else {
                continue
            }
            
            annotationsToRemove[place.identifier] = place
            
            for article in place.articles {
                guard let key = article.key else {
                    continue
                }
                previousPlaceByArticle[key] = place
            }
        }
        
        var groups: [QuadKey: ArticleGroup] = [:]

        for article in articles {
            guard let quadKey = article.quadKey else {
                continue
            }
            var group: ArticleGroup
            let adjustedQuadKey: QuadKey
            if groupingPrecision < maxPrecision {
                adjustedQuadKey = quadKey.adjusted(downBy: QuadKeyPrecision.maxPrecision - groupingPrecision)
                group = groups[adjustedQuadKey] ?? ArticleGroup()
            } else {
                group = ArticleGroup()
                adjustedQuadKey = quadKey
            }
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
                    guard adjustedQuadKey != quadKey, let adjacentGroup = groups[adjustedQuadKey], adjacentGroup.articles.count > 1 || group.articles.count > 1 else {
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
            
            var nextCoordinate: CLLocationCoordinate2D?
            var coordinate = group.location.coordinate

            let identifier = ArticlePlace.identifierForArticles(articles: group.articles)
            
            //check for identical place already on the map
            if annotationsToRemove.removeValue(forKey: identifier) != nil {
                continue
            }

            if group.articles.count == 1 {
                if let article = group.articles.first, let key = article.key, let previousPlace = previousPlaceByArticle[key] {
                    nextCoordinate = coordinate
                    coordinate = previousPlace.coordinate
                }
            } else {
                let groupCount = group.articles.count
                for article in group.articles {
                    guard let key = article.key, let previousPlace = previousPlaceByArticle[key], previousPlace.articles.count < groupCount, annotationsToRemove.removeValue(forKey: previousPlace.identifier) != nil else {
                        continue
                    }
                    
                    let placeView = mapView.view(for: previousPlace)
                    taskGroup.enter()
                    UIView.animate(withDuration: animationDuration, animations: {
                        placeView?.alpha = 0
                        if (previousPlace.articles.count > 1) {
                            placeView?.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
                        }
                        previousPlace.coordinate = coordinate
                    }, completion: { (finished) in
                        taskGroup.leave()
                        self.mapView.removeAnnotation(previousPlace)
                    })
                }
            }
            
            guard let place = ArticlePlace(coordinate: coordinate, nextCoordinate: nextCoordinate, articles: group.articles, identifier: identifier) else {
                continue
            }
            
            mapView.addAnnotation(place)
        }
        
        for (_, annotation) in annotationsToRemove {
            let placeView = mapView.view(for: annotation)
            taskGroup.enter()
            UIView.animate(withDuration: 0.5*animationDuration, animations: {
                placeView?.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
                placeView?.alpha = 0
            }, completion: { (finished) in
                taskGroup.leave()
                self.mapView.removeAnnotation(annotation)
            })
        }
        currentGroupingPrecision = groupingPrecision
        taskGroup.waitInBackground {
            self.groupingTaskGroup = nil
            if (self.needsRegroup) {
                self.needsRegroup = false
                self.regroupArticlesIfNecessary(forVisibleRegion: self.mapRegion ?? self.mapView.region)
            }
        }
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
        updatePlaces()
    }
    
    func updatePlaces() {
        listView.reloadData()
        currentGroupingPrecision = 0
        regroupArticlesIfNecessary(forVisibleRegion: mapRegion ?? mapView.region)
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
        dismissCurrentArticlePopover()
        
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
    
    var fetchRequestForSavedArticles: NSFetchRequest<WMFArticle> {
        get {
            let savedRequest = WMFArticle.fetchRequest()
            savedRequest.predicate = NSPredicate(format: "savedDate != NULL")
            return savedRequest
        }
    }
    
    var fetchRequestForSavedArticlesWithLocation: NSFetchRequest<WMFArticle> {
        get {
            let savedRequest = WMFArticle.fetchRequest()
            savedRequest.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey != NULL")
            return savedRequest
        }
    }
    
    // Search completions
    
    func updateSearchSuggestions(withCompletions completions: [PlaceSearch]) {
        guard let currentSearchString = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines), currentSearchString != "" || completions.count > 0 else {
            let topNearbySuggestion = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStylePageViews, string: nil, region: nil, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby"), searchCompletion: nil)
            let topLinksSuggestion = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStyleLinks, string: nil, region: nil, localizedDescription: "Top by links", searchCompletion: nil)
            let topCombinedSuggestion = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStylePageViewsAndLinks, string: nil, region: nil, localizedDescription: "Top by page views and links", searchCompletion: nil)
            let topDefaultSuggestion = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStyleNone, string: nil, region: nil, localizedDescription: "Nearby with no sort param", searchCompletion: nil)
            
            var suggestedSearches = [topNearbySuggestion, topLinksSuggestion, topCombinedSuggestion, topDefaultSuggestion]
            var recentSearches: [PlaceSearch] = []
            do {
                let moc = dataStore.viewContext
                if try moc.count(for: fetchRequestForSavedArticles) > 0 {
                    let saved = PlaceSearch(type: .saved, sortStyle: WMFLocationSearchSortStyleNone, string: nil, region: nil, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-saved-articles"), searchCompletion: nil)
                    suggestedSearches.append(saved)
                }
              
                let request = WMFKeyValue.fetchRequest()
                request.predicate = NSPredicate(format: "group == %@", searchHistoryGroup)
                request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                let results = try moc.fetch(request)
                recentSearches = try results.map({ (kv) -> PlaceSearch in
                    guard let dictionary = kv.value as? [String : Any],
                        let ps = PlaceSearch(dictionary: dictionary) else {
                            throw NSError()
                    }
                    return ps
                })
            } catch let error {
                DDLogError("Error fetching recent place searches: \(error)")
            }
            
            searchSuggestionController.searches = [suggestedSearches, recentSearches, [], []]
            return
        }
        
        let currentStringSuggeston = PlaceSearch(type: .text, sortStyle: WMFLocationSearchSortStylePageViews, string: currentSearchString, region: nil, localizedDescription: currentSearchString, searchCompletion: nil)
        searchSuggestionController.searches = [[], [], [currentStringSuggeston], completions]
    }
    
    func updateSearchCompletionsFromSearchBarText() {
        guard let text = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines), text != "" else {
            updateSearchSuggestions(withCompletions: [])
            return
        }
        localCompleter.queryFragment = text
        globalCompleter.queryFragment = text
    }
    
    // UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let type = currentSearch?.type, type != .text {
            searchBar.text = nil
        }
        updateSearchSuggestions(withCompletions: [])
        searchSuggestionView.isHidden = false
        deselectAllAnnotations()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchSuggestions(withCompletions: searchSuggestionController.searches[3])
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(updateSearchCompletionsFromSearchBarText), with: nil, afterDelay: 0.2)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentSearch = PlaceSearch(type: .text, sortStyle: WMFLocationSearchSortStylePageViews, string: searchBar.text, region: nil, localizedDescription: searchBar.text, searchCompletion: nil)
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchSuggestionView.isHidden = true
    }
    
    //UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFNearbyArticleTableViewCell.identifier(), for: indexPath) as? WMFNearbyArticleTableViewCell else {
            return UITableViewCell()
        }
        
        let article = articles[indexPath.row]
        cell.titleText = article.displayTitle
        cell.descriptionText = article.wikidataDescription
        cell.setImageURL(article.thumbnailURL)
        
        update(userLocation: mapView.userLocation, onLocationCell: cell, withArticle: article)
     
        return cell
    }
    
    func update(userLocation: MKUserLocation, onLocationCell cell: WMFNearbyArticleTableViewCell, withArticle article: WMFArticle) {
        guard let articleLocation = article.location, let userLocation = userLocation.location else {
            return
        }
        
        let distance = articleLocation.distance(from: userLocation)
        cell.setDistance(distance)
        
        if let heading = mapView.userLocation.heading  {
            let bearing = userLocation.wmf_bearing(to: articleLocation, forCurrentHeading: heading)
            cell.setBearing(bearing)
        } else {
            let bearing = userLocation.wmf_bearing(to: articleLocation)
            cell.setBearing(bearing)
        }
    }
    
    // UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articles[indexPath.row]
        guard let url = article.url else {
            return
        }
        wmf_pushArticle(with: url, dataStore: dataStore, previewStore: articleStore, animated: true)
    }
    
    // MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        var completions: [PlaceSearch] = []
        var titles: Set<String> = []
        var results = localCompleter.results
        results.append(contentsOf: globalCompleter.results)
        
        for result in results {
            guard !titles.contains(result.title) else {
                continue
            }
            titles.update(with: result.title)
            let search = PlaceSearch(type: .location, sortStyle: WMFLocationSearchSortStyleNone, string: nil, region: nil, localizedDescription: result.title, searchCompletion: result)
            completions.append(search)
        }
        
        updateSearchSuggestions(withCompletions: completions)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
       DDLogWarn("completerDidFail: \(error)")
    }
    
    // PlaceSearchSuggestionControllerDelegate
    
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didSelectSearch search: PlaceSearch) {
        currentSearch = search
        searchBar.endEditing(true)
    }
    
    func placeSearchSuggestionControllerClearButtonPressed(_ controller: PlaceSearchSuggestionController) {
        clearSearchHistory()
        updateSearchSuggestions(withCompletions: [])
    }
    
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didDeleteSearch search: PlaceSearch) {
        let moc = dataStore.viewContext
        guard let kv = keyValue(forPlaceSearch: search, inManagedObjectContext: moc) else {
            return
        }
        moc.delete(kv)
        do {
           try moc.save()
        } catch let error {
            DDLogError("Error removing kv: \(error.localizedDescription)")
        }
        updateSearchSuggestions(withCompletions: [])
    }
    
    // WMFLocationManagerDelegate
    
    func locationManager(_ controller: WMFLocationManager, didUpdate location: CLLocation) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 5000, 5000)
        mapRegion = region
        if currentSearch == nil {
            currentSearch = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStylePageViews, string: nil, region: region, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby"), searchCompletion: nil)
        }
        locationManager.stopMonitoringLocation()
    }
    
    func locationManager(_ controller: WMFLocationManager, didReceiveError error: Error) {
        locationManager.stopMonitoringLocation()
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate heading: CLHeading) {
    }
    
    func locationManager(_ controller: WMFLocationManager, didChangeEnabledState enabled: Bool) {
    }
    
    @IBAction func recenterOnUserLocation(_ sender: Any) {
       locationManager.startMonitoringLocation()
    }
    
    @IBOutlet weak var secretSettingsView: UIView!

    
    @IBOutlet weak var maxZoomLabel: UILabel!
    @IBOutlet weak var maxZoomSlider: UISlider!
    @IBAction func maxZoomValueChanged(_ sender: Any) {
        maxZoomLabel.text = "max: \(Int(round(maxZoomSlider.value)))"
        applySecretSettings()
    }
    
    @IBOutlet weak var groupZoomDeltaLabel: UILabel!
    @IBOutlet weak var groupZoomDeltaSlider: UISlider!
    @IBAction func groupZoomDeltaSliderChanged(_ sender: Any) {
        groupZoomDeltaLabel.text = "delta: \(Int(8 - round(groupZoomDeltaSlider.value)))"
        applySecretSettings()
    }
    
    @IBOutlet weak var groupAggressivenessLabel: UILabel!
    @IBOutlet weak var groupAggressivenessSlider: UISlider!
    @IBAction func groupAggressivenessChanged(_ sender: Any) {
        groupAggressivenessLabel.text = String(format: "agg: %.2f", groupAggressivenessSlider.value)
        applySecretSettings()
    }
    
    func applySecretSettings() {
        groupingAggressiveness = CLLocationDistance(groupAggressivenessSlider.value)
        groupingPrecisionDelta = QuadKeyPrecision(8 - round(groupZoomDeltaSlider.value))
        maxGroupingPrecision = QuadKeyPrecision(round(maxZoomSlider.value))
        currentGroupingPrecision = 0
        regroupArticlesIfNecessary(forVisibleRegion: mapRegion ?? mapView.region)
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        switch motion {
        case .motionShake:
            secretSettingsView.isHidden = !secretSettingsView.isHidden
            guard secretSettingsView.isHidden else {
                return
            }
           applySecretSettings()
        default:
            break
        }
    }
}

