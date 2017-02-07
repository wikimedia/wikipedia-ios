import UIKit
import MapKit
import WMF
import TUSafariActivity

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, ArticlePopoverViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, PlaceSearchSuggestionControllerDelegate, WMFLocationManagerDelegate {
    
    @IBOutlet weak var redoSearchButton: UIButton!
    let locationSearchFetcher = WMFLocationSearchFetcher()
    let searchFetcher = WMFSearchFetcher()
    let previewFetcher = WMFArticlePreviewFetcher()
    
    let locationManager = WMFLocationManager.coarse()
    
    let animationDuration = 0.6
    let animationScale = CGFloat(0.6)
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var progressView: UIProgressView!
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
    
    var maxGroupingPrecision: QuadKeyPrecision = 16
    var groupingPrecisionDelta: QuadKeyPrecision = 4
    var groupingAggressiveness: CLLocationDistance = 0.67
    
    var currentArticlePopover: ArticlePopoverViewController?
    
    var placeToSelect: ArticlePlace?
    var articleKeyToSelect: String?
    
    var currentSearch: PlaceSearch? {
        didSet {
            guard let search = currentSearch else {
                return
            }
            searchBar.text = search.localizedDescription
            performSearch(search)
            
            
            switch search.type {
            case .saved:
                break
            case .top:
                break
            case .location:
                guard !search.needsWikidataQuery else {
                    break
                }
                fallthrough
            default:
                saveToHistory(search: search)
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
        
        // TODO: Remove
        let defaults = UserDefaults.wmf_userDefaults()
        let key = "WMFDidClearPlaceSearchHistory"
        if !defaults.bool(forKey: key) {
            clearSearchHistory()
            defaults.set(true, forKey: key)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        guard let toSelect = placeToSelect else {
            return
        }
        
        placeToSelect = nil
        
        guard let articleToSelect = toSelect.articles.first else {
            return
        }
        
        let annotations = mapView.annotations(in: mapView.visibleMapRect)
        for annotation in annotations {
            guard let place = annotation as? ArticlePlace,
                place.articles.count == 1,
                let article = place.articles.first,
                article.key == articleToSelect.key else {
                    continue
            }
            mapView.selectAnnotation(place, animated: true)
            break
        }
        
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
    
    func regionThatFits(articles: [WMFArticle]) -> MKCoordinateRegion {
        return regionThatFits(coordinates: articles.flatMap({ (article) -> CLLocationCoordinate2D? in
            return article.coordinate
        }))
    }
    
    func regionThatFits(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var rect: MKMapRect?
        
        for coordinate in coordinates {
            let point = MKMapPointForCoordinate(coordinate)
            let size = MKMapSize(width: 0, height: 0)
            let coordinateRect = MKMapRect(origin: point, size: size)
            guard let currentRect = rect else {
                rect = coordinateRect
                continue
            }
            rect = MKMapRectUnion(currentRect, coordinateRect)
        }
        
        guard let finalRect = rect else {
            return MKCoordinateRegion()
        }
        
        var region = MKCoordinateRegionForMapRect(finalRect)
        region.span.latitudeDelta = max(0.1, 1.3*region.span.latitudeDelta)
        region.span.longitudeDelta = max(0.1, 1.3*region.span.longitudeDelta)
        return region
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotationView: MKAnnotationView) {
        guard let place = annotationView.annotation as? ArticlePlace else {
            return
        }
        
        guard place.articles.count == 1 else {
            placeToSelect = place
            mapRegion = regionThatFits(articles: place.articles)
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
                self.mapRegion = self.regionThatFits(articles: articlesToShow)
                self.searching = false
                self.updatePlaces()
                
                if articlesToShow.count == 0 {
                    self.wmf_showAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("places-no-saved-articles-have-location"))
                }
            }
            
            do {
                let savedPagesWithLocation = try moc.fetch(fetchRequestForSavedArticlesWithLocation)
                guard savedPagesWithLocation.count >= 99 else {
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
            guard search.needsWikidataQuery else {
                fallthrough
            }
            let fail = {
                dispatchOnMainQueue({
                    if let region = search.region {
                        self.mapRegion = region
                    }
                    self.searching = false
                    var newSearch = search
                    newSearch.needsWikidataQuery = false
                    self.currentSearch = newSearch
                })
            }
            guard let key = search.articleKey,
                let articleURL = URL(string: key),
                let title = (articleURL as NSURL).wmf_title,
                let language = (articleURL as NSURL).wmf_language  else {
                    fail()
                    return
            }
            var components = URLComponents()
            components.host = "wikidata.org"
            components.path = "/w/api.php"
            components.scheme = "https"
            let actionQueryItem = URLQueryItem(name: "action", value: "wbgetentities")
            let titlesQueryItem = URLQueryItem(name: "titles", value: title)
            let sitesQueryItem = URLQueryItem(name: "sites", value: "\(language)wiki")
            let formatQueryItem = URLQueryItem(name: "format", value: "json")
            components.queryItems = [actionQueryItem, titlesQueryItem, sitesQueryItem, formatQueryItem]
            
            guard let requestURL = components.url else {
                fail()
                return
            }
            
            let northernmostPointKey = "P1332"
            let southernmostPointKey = "P1333"
            let easternmostPointKey = "P1334"
            let westernmostPointKey = "P1335"
            let keys = [northernmostPointKey, southernmostPointKey, easternmostPointKey, westernmostPointKey]
            URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                guard let data = data else {
                    fail()
                    return
                }
                do {
                    guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                        fail()
                        return
                    }
                    guard let entities = jsonObject["entities"] as? [String: Any] else {
                        fail()
                        return
                    }
                    guard let entity = entities.values.first as? [String: Any] else {
                        fail()
                        return
                    }
                    guard let claims = entity["claims"] as? [String: Any] else {
                        fail()
                        return
                    }
                    
                    let coordinates = keys.flatMap({ (key) -> CLLocationCoordinate2D? in
                        guard let values = claims[key] as? [Any] else {
                            return nil
                        }
                        guard let point = values.first as? [String: Any] else {
                            return nil
                        }
                        guard let mainsnak = point["mainsnak"] as? [String: Any] else {
                            return nil
                        }
                        guard let datavalue = mainsnak["datavalue"] as? [String: Any] else {
                            return nil
                        }
                        guard let value = datavalue["value"] as? [String: Any] else {
                            return nil
                        }
                        guard let latitude = value["latitude"] as? CLLocationDegrees,
                            let longitude = value["longitude"] as? CLLocationDegrees else {
                                return nil
                        }
                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    })
                    
                    guard coordinates.count > 3 else {
                        fail()
                        return
                    }
                    
                    dispatchOnMainQueue({
                        let region = self.regionThatFits(coordinates: coordinates)
                        self.mapRegion = region
                        self.searching = false
                        var newSearch = search
                        newSearch.needsWikidataQuery = false
                        newSearch.region = region
                        self.currentSearch = newSearch
                    })
                } catch let parseError {
                    DDLogError("error parsing JSON \(parseError)")
                }
            }).resume()
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
        
        let done = {
            self.searching = false
            self.progressView.setProgress(1.0, animated: true)
            self.isProgressHidden = true
        }
        isProgressHidden = false
        progressView.setProgress(0, animated: false)
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
        locationSearchFetcher.fetchArticles(withSiteURL: siteURL, in: searchRegion, matchingSearchTerm: searchTerm, sortStyle: sortStyle, resultLimit: 50, completion: { (searchResults) in
            self.updatePlaces(withSearchResults: searchResults.results)
            done()
        }) { (error) in
            self.wmf_showAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("empty-no-search-results-message"))
            done()
        }
    }
    
    func incrementProgress() {
        guard !isProgressHidden && progressView.progress <= 0.69 else {
            return
        }
        
        let rand = 0.15 + Float(arc4random_uniform(15))/100
        progressView.setProgress(progressView.progress + rand, animated: true)
        perform(#selector(incrementProgress), with: nil, afterDelay: 0.3)
    }
    
    func hideProgress() {
        UIView.animate(withDuration: 0.3, animations: { self.progressView.alpha = 0 } )
    }
    
    func showProgress() {
        progressView.alpha = 1
    }
    
    var isProgressHidden: Bool = false {
        didSet{
            if isProgressHidden {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showProgress), object: nil)
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(incrementProgress), object: nil)
                perform(#selector(hideProgress), with: nil, afterDelay: 0.7)
            } else {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideProgress), object: nil)
                showProgress()
            }
        }
    }
    
    @IBAction func redoSearch(_ sender: Any) {
        guard let search = currentSearch else {
            return
        }
        currentSearch = PlaceSearch(type: search.type, sortStyle: search.sortStyle, string: search.string, region: nil, localizedDescription: search.localizedDescription, articleKey: search.articleKey)
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
            if groupingPrecision < maxPrecision && (articleKeyToSelect == nil || article.key != articleKeyToSelect) {
                adjustedQuadKey = quadKey.adjusted(downBy: QuadKeyPrecision.maxPrecision - groupingPrecision)
                group = groups[adjustedQuadKey] ?? ArticleGroup()
            } else {
                group = ArticleGroup()
                adjustedQuadKey = quadKey
            }
            if let keyToSelect = articleKeyToSelect, group.articles.first?.key == keyToSelect {
                // leave out articles that would be grouped with the one to select
                continue
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
            
            if let keyToSelect = articleKeyToSelect, place.articles.first?.key == keyToSelect {
                // hacky workaround for now
                deselectAllAnnotations()
                placeToSelect = place
                dispatchAfterDelayInSeconds(0.5, DispatchQueue.main, {
                    self.placeToSelect = nil
                    guard self.mapView.selectedAnnotations.count == 0 else {
                        return
                    }
                    self.mapView.selectAnnotation(place, animated: true)
                })
                articleKeyToSelect = nil
            }
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
        articleKeyToSelect = currentSearch?.articleKey
        var foundKey = false
        for result in searchResults {
            guard let displayTitle = result.displayTitle,
                let articleURL = (siteURL as NSURL).wmf_URL(withTitle: displayTitle),
                let article = self.articleStore?.addPreview(with: articleURL, updatedWith: result),
                let _ = article.quadKey else {
                    continue
            }
            if articleKeyToSelect != nil && articleKeyToSelect == article.key {
                foundKey = true
            }
            articles.append(article)
        }
        
        if !foundKey, let keyToFetch = articleKeyToSelect, let fetchedArticle = self.dataStore.fetchArticle(forKey: keyToFetch) {
            articles.append(fetchedArticle)
        }
        
        updatePlaces()
    }
    
    func updatePlaces() {
        listView.reloadData()
        currentGroupingPrecision = 0
        regroupArticlesIfNecessary(forVisibleRegion: mapRegion ?? mapView.region)
    }
    
    
    // ArticlePopoverViewControllerDelegate
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction: ArticlePopoverViewControllerAction) {
        
        
        guard let article = articlePopoverViewController.article, let url = article.url else {
            return
        }
        
        switch didSelectAction {
        case .read:
            wmf_pushArticle(with: url, dataStore: dataStore, previewStore: articleStore, animated: true)
            break
        case .save:
            deselectAllAnnotations()
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
            let topNearbySuggestion = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStyleLinks, string: nil, region: nil, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby"), articleKey: nil)
            
            var suggestedSearches = [topNearbySuggestion]
            var recentSearches: [PlaceSearch] = []
            do {
                let moc = dataStore.viewContext
                if try moc.count(for: fetchRequestForSavedArticles) > 0 {
                    let saved = PlaceSearch(type: .saved, sortStyle: WMFLocationSearchSortStyleNone, string: nil, region: nil, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-saved-articles"), articleKey: nil)
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
        
        guard currentSearchString != "" else {
            searchSuggestionController.searches = [[], [], [], completions]
            return
        }
        
        let currentStringSuggeston = PlaceSearch(type: .text, sortStyle: WMFLocationSearchSortStyleLinks, string: currentSearchString, region: nil, localizedDescription: currentSearchString, articleKey: nil)
        searchSuggestionController.searches = [[], [], [currentStringSuggeston], completions]
    }
    
    func handleCompletion(searchResults: [MWKSearchResult]) {
        let completions = searchResults.flatMap { (result) -> PlaceSearch? in
            guard let location = result.location,
                let dimension = result.geoDimension?.doubleValue,
                let title = result.displayTitle,
                let url = (self.siteURL as NSURL).wmf_URL(withTitle: title),
                let article = self.articleStore?.addPreview(with: url, updatedWith: result),
                let key = article.key else {
                    return nil
            }
            
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, dimension, dimension)
            return PlaceSearch(type: .location, sortStyle: WMFLocationSearchSortStyleLinks, string: nil, region: region, localizedDescription: result.displayTitle, articleKey: key)
        }
        updateSearchSuggestions(withCompletions: completions)
    }
    
    
    func updateSearchCompletionsFromSearchBarText() {
        guard let text = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines), text != "" else {
            updateSearchSuggestions(withCompletions: [])
            return
        }
        
        searchFetcher.fetchArticles(forSearchTerm: text, siteURL: siteURL, resultLimit: 24, failure: { (error) in
            self.updateSearchSuggestions(withCompletions: [])
        }) { (searchResult) in
            guard let results = searchResult.results, results.count > 0 else {
                let center = self.mapView.userLocation.coordinate
                let region = CLCircularRegion(center: center, radius: 40075000, identifier: "world")
                self.locationSearchFetcher.fetchArticles(withSiteURL: self.siteURL, in: region, matchingSearchTerm: text, sortStyle: WMFLocationSearchSortStyleLinks, resultLimit: 50, completion: { (results) in
                    self.handleCompletion(searchResults: results.results)
                }) { (error) in
                    self.updateSearchSuggestions(withCompletions: [])
                }
                return
            }
            self.handleCompletion(searchResults: results)
        }
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
        currentSearch = PlaceSearch(type: .text, sortStyle: WMFLocationSearchSortStyleLinks, string: searchBar.text, region: nil, localizedDescription: searchBar.text, articleKey: nil)
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
            currentSearch = PlaceSearch(type: .top, sortStyle: WMFLocationSearchSortStyleLinks, string: nil, region: region, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby"), articleKey: nil)
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
    
    // Grouping debug view
    
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

