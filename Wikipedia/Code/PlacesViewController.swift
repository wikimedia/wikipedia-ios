import UIKit
import MapKit
import WMF
import TUSafariActivity

class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, ArticlePopoverViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, PlaceSearchSuggestionControllerDelegate, WMFLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var redoSearchButton: UIButton!
    let locationSearchFetcher = WMFLocationSearchFetcher()
    let searchFetcher = WMFSearchFetcher()
    let previewFetcher = WMFArticlePreviewFetcher()
    let wikidataFetcher = WikidataFetcher()
    
    let locationManager = WMFLocationManager.fine()
    
    let animationDuration = 0.6
    let animationScale = CGFloat(0.6)
    let popoverFadeDuration = 0.25
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var listView: UITableView!
    @IBOutlet weak var searchSuggestionView: UITableView!
    @IBOutlet weak var recenterOnUserLocationButton: UIButton!
    
    var searchSuggestionController: PlaceSearchSuggestionController!
    
    var searchBar: UISearchBar!
    var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    var articleFetchedResultsController = NSFetchedResultsController<WMFArticle>() {
        didSet {
            oldValue.delegate = nil
            for article in oldValue.fetchedObjects ?? [] {
                article.placesSortOrder = nil
            }
            do {
                try dataStore.viewContext.save()
                try articleFetchedResultsController.performFetch()
            } catch let fetchError {
                DDLogError("Error fetching articles for places: \(fetchError)")
            }
            updatePlaces()
            articleFetchedResultsController.delegate = self
        }
    }

    var articleStore: WMFArticleDataStore!
    var dataStore: MWKDataStore!
    var segmentedControl: UISegmentedControl!
    
    var currentGroupingPrecision: QuadKeyPrecision = 1
    
    let searchHistoryGroup = "PlaceSearch"
    
    var maxGroupingPrecision: QuadKeyPrecision = 16
    var groupingPrecisionDelta: QuadKeyPrecision = 4
    var groupingAggressiveness: CLLocationDistance = 0.67
    
    var selectedArticlePopover: ArticlePopoverViewController?
    var selectedArticleKey: String?
    
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
    
    func performDefaultSearch(withRegion region: MKCoordinateRegion) {
        guard currentSearch == nil else {
            return
        }
        currentSearch = PlaceSearch(type: .top, sortStyle: .links, string: nil, region: region, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles"), searchResult: nil)
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
        
        redoSearchButton.setTitle("          " + localizedStringForKeyFallingBackOnEnglish("places-search-this-area")  + "          ", for: .normal)
        
        // Setup map view
        mapView.mapType = .standard
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsPointsOfInterest = false
        mapView.showsScale = true
        mapView.showsUserLocation = true
        
        // Setup location manager
        locationManager.delegate = self
        
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
        let searchBarLeftPadding: CGFloat = 7.5
        let searchBarRightPadding: CGFloat = 2.5
        searchBar = UISearchBar(frame: CGRect(x: searchBarLeftPadding, y: 0, width: view.bounds.size.width - searchBarLeftPadding - searchBarRightPadding, height: 32))
        //searchBar.keyboardType = .webSearch
        searchBar.returnKeyType = .search
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 32))
        titleView.addSubview(searchBar)
        navigationItem.titleView = titleView
        
        // Setup search suggestions
        searchSuggestionController = PlaceSearchSuggestionController()
        searchSuggestionController.tableView = searchSuggestionView
        searchSuggestionController.delegate = self
        
        
    }
    
    var performDefaultSearchOnNextMapRegionUpdate = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if WMFLocationManager.isAuthorized() {
            recenterOnUserLocationButton.isHidden = false
            locationManager.startMonitoringLocation()
        } else {
            recenterOnUserLocationButton.isHidden = true
            performDefaultSearchOnNextMapRegionUpdate = currentSearch == nil
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        locationManager.stopMonitoringLocation()
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
        guard performDefaultSearchOnNextMapRegionUpdate == false else {
            performDefaultSearch(withRegion: mapView.region)
            return
        }
        regroupArticlesIfNecessary(forVisibleRegion: mapView.region)
        articleKeyToSelect = nil
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
            selectArticlePlace(place)
            break
        }
        
    }
    
    var previouslySelectedArticlePlaceIdentifier: String?
    func selectArticlePlace(_ articlePlace: ArticlePlace) {
        mapView.selectAnnotation(articlePlace, animated: articlePlace.identifier != previouslySelectedArticlePlaceIdentifier)
        previouslySelectedArticlePlaceIdentifier = articlePlace.identifier
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
        let coordinates: [CLLocationCoordinate2D] =  articles.flatMap({ (article) -> CLLocationCoordinate2D? in
            return article.coordinate
        })
        return coordinates.wmf_boundingRegion
    }
    
    func adjustLayout(ofPopover articleVC: ArticlePopoverViewController, withSize size: CGSize,  withAnnotationView annotationView: MKAnnotationView) {
        let annotationCenter = view.convert(annotationView.center, from: mapView)
        let center = CGPoint(x: view.bounds.midX, y:  view.bounds.midY)
        let deltaX = annotationCenter.x - center.x
        let deltaY = annotationCenter.y - center.y
        
        let thresholdX = 0.5*(abs(view.bounds.width - size.width))
        let thresholdY = 0.5*(abs(view.bounds.height - size.height))
        
        var offsetX: CGFloat
        var offsetY: CGFloat
        
        let distanceFromAnnotationView: CGFloat = 5
        let distanceX: CGFloat = round(0.5*annotationView.bounds.size.width) + distanceFromAnnotationView
        let distanceY: CGFloat =  round(0.5*annotationView.bounds.size.height) + distanceFromAnnotationView

        if abs(deltaX) <= thresholdX {
            offsetX = -0.5 * size.width
            offsetY = deltaY > 0 ? 0 - distanceY - size.height : distanceY
        } else if abs(deltaY) <= thresholdY {
            offsetX = deltaX > 0 ? 0 - distanceX - size.width : distanceX
            offsetY = -0.5 * size.height
        } else {
            offsetX = deltaX > 0 ? 0 - distanceX - size.width : distanceX
            offsetY = deltaY > 0 ? 0 - distanceY - size.height : distanceY
        }
        
        articleVC.view.frame = CGRect(origin: CGPoint(x: annotationCenter.x + offsetX, y: annotationCenter.y + offsetY), size: size)
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotationView: MKAnnotationView) {
        guard let place = annotationView.annotation as? ArticlePlace else {
            return
        }
        
        previouslySelectedArticlePlaceIdentifier = place.identifier

        guard place.articles.count == 1 else {
            articleKeyToSelect = place.articles.first?.key
            mapRegion = regionThatFits(articles: place.articles)
            return
        }
        
        showPopover(forAnnotationView: annotationView)
    }
    
    
    
    func showPopover(forAnnotationView annotationView: MKAnnotationView) {
        guard let place = annotationView.annotation as? ArticlePlace else {
            return
        }
        
        guard let article = place.articles.first,
            let coordinate = article.coordinate,
            let articleKey = article.key else {
                return
        }
        
        guard selectedArticlePopover == nil else {
            return
        }
        
        let articleVC = ArticlePopoverViewController(article)
        articleVC.delegate = self
        articleVC.view.tintColor = view.tintColor
        articleVC.configureView(withTraitCollection: traitCollection)
        
        let articleLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let userCoordinate = mapView.userLocation.coordinate
        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        
        let distance = articleLocation.distance(from: userLocation)
        let distanceString = MKDistanceFormatter().string(fromDistance: distance)
        articleVC.descriptionLabel.text = distanceString
        
        articleVC.view.alpha = 0
        addChildViewController(articleVC)
        view.insertSubview(articleVC.view, aboveSubview: mapView)
        articleVC.didMove(toParentViewController: self)
        
        let size = articleVC.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        selectedArticlePopover = articleVC
        selectedArticleKey = articleKey
        adjustLayout(ofPopover: articleVC, withSize:size, withAnnotationView: annotationView)
    
        articleVC.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: popoverFadeDuration) {
            articleVC.view.transform = CGAffineTransform.identity
            articleVC.view.alpha = 1
        }
    }
    
    
    func dismissCurrentArticlePopover() {
        guard let popover = selectedArticlePopover else {
            return
        }
        UIView.animate(withDuration: popoverFadeDuration, animations: {
            popover.view.alpha = 0
            popover.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (done) in
            popover.willMove(toParentViewController: nil)
            popover.view.removeFromSuperview()
            popover.removeFromParentViewController()
        }
        selectedArticlePopover = nil
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        selectedArticleKey = nil
        dismissCurrentArticlePopover()
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let place = annotation as? ArticlePlace else {
            // CRASH WORKAROUND 
            // The UIPopoverController that the map view presents from the default user location annotation is causing a crash. Using our own annotation view for the user location works around this issue.
            if let userLocation = annotation as? MKUserLocation {
                let userViewReuseIdentifier = "org.wikimedia.userLocationAnnotationView"
                let placeView = mapView.dequeueReusableAnnotationView(withIdentifier: userViewReuseIdentifier) as? UserLocationAnnotationView ?? UserLocationAnnotationView(annotation: userLocation, reuseIdentifier: userViewReuseIdentifier)
                placeView.annotation = userLocation
                return placeView
            }
            return nil
        }
        
        let reuseIdentifier = "org.wikimedia.articlePlaceView"
        var placeView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as! ArticlePlaceView?
        
        if placeView == nil {
            placeView = ArticlePlaceView(annotation: place, reuseIdentifier: reuseIdentifier)
        } else {
            placeView?.prepareForReuse()
            placeView?.annotation = place
        }
        
        if showingAllImages {
            placeView?.set(alwaysShowImage: true, animated: false)
        }
        
        if place.articles.count > 1 && place.nextCoordinate == nil {
            placeView?.alpha = 0
            placeView?.transform = CGAffineTransform(scaleX: animationScale, y: animationScale)
            dispatchOnMainQueue({
                UIView.animate(withDuration: self.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                    placeView?.transform = CGAffineTransform.identity
                    placeView?.alpha = 1
                }, completion: nil)
            })
        } else if let nextCoordinate = place.nextCoordinate {
            placeView?.alpha = 0
            dispatchOnMainQueue({
                UIView.animate(withDuration: 2*self.animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                    place.coordinate = nextCoordinate
                }, completion: nil)
                UIView.animate(withDuration: 0.5*self.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                    placeView?.alpha = 1
                }, completion: nil)
            })
        } else {
            placeView?.alpha = 0
            dispatchOnMainQueue({
                UIView.animate(withDuration: self.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                    placeView?.alpha = 1
                }, completion: nil)
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
    
    func showSavedArticles() {
        let moc = dataStore.viewContext
        let done = { (articlesToShow: [WMFArticle]) -> Void in
            let request = WMFArticle.fetchRequest()
            request.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey != NULL")
            request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
            self.articleFetchedResultsController = NSFetchedResultsController<WMFArticle>(fetchRequest: request, managedObjectContext: self.dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            if articlesToShow.count > 0 {
                self.mapRegion = self.regionThatFits(articles: articlesToShow)
            }
            self.searching = false
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
    }
    
    func performWikidataQuery(forSearch search: PlaceSearch) {
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
        guard let articleURL = search.searchResult?.articleURL(forSiteURL: siteURL) else {
            fail()
            return
        }
        
        wikidataFetcher.wikidataBoundingRegion(forArticleURL: articleURL, failure: { (error) in
            DDLogError("Error fetching bounding region from Wikidata: \(error)")
            fail()
        }, success: { (region) in
            dispatchOnMainQueue({
                self.mapRegion = region
                self.searching = false
                var newSearch = search
                newSearch.needsWikidataQuery = false
                newSearch.region = region
                self.currentSearch = newSearch
            })
        })
    }
    
    func performSearch(_ search: PlaceSearch) {
        guard !searching else {
            return
        }
        searching = true
        redoSearchButton.isHidden = true
        
        deselectAllAnnotations()
        
        let siteURL = self.siteURL
        var searchTerm: String? = nil
        let sortStyle = search.sortStyle
        let region = search.region ?? mapRegion ?? mapView.region
        currentSearchRegion = region
        
        switch search.type {
        case .saved:
            showSavedArticles()
            return
        case .top:
            break
        case .location:
            guard search.needsWikidataQuery else {
                fallthrough
            }
            performWikidataQuery(forSearch: search)
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
        currentSearch = PlaceSearch(type: search.type, sortStyle: search.sortStyle, string: search.string, region: nil, localizedDescription: search.localizedDescription, searchResult: search.searchResult)
        redoSearchButton.isHidden = true
    }
    
    var groupingTaskGroup: WMFTaskGroup?
    var needsRegroup = false
    var showingAllImages = false
    
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
        let currentPrecision = lowestPrecision + groupingPrecisionDelta
        let groupingPrecision = min(maxPrecision, currentPrecision)
        
        guard let searchRegion = currentSearchRegion else {
            return
        }
        
        let searchDeltaLon = searchRegion.span.longitudeDelta
        let lowestSearchPrecision = QuadKeyPrecision(deltaLongitude: searchDeltaLon)
        let currentSearchPrecision = lowestSearchPrecision + groupingPrecisionDelta
        let shouldShowAllImages = currentPrecision > maxPrecision + 1 || currentPrecision >= currentSearchPrecision + 1

        if shouldShowAllImages != showingAllImages {
            for annotation in mapView.annotations {
                guard let view = mapView.view(for: annotation) as? ArticlePlaceView else {
                    continue
                }
                view.set(alwaysShowImage: shouldShowAllImages, animated: true)
            }
            showingAllImages = shouldShowAllImages
        }
        
        guard groupingPrecision != currentGroupingPrecision else {
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
        
        for article in articleFetchedResultsController.fetchedObjects ?? [] {
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
                    if let keyToSelect = articleKeyToSelect,
                        group.articles.first?.key == keyToSelect || adjacentGroup.articles.first?.key == keyToSelect {
                        //no grouping with the article to select
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
            
            let checkAndSelect = { (place: ArticlePlace) in
                if let keyToSelect = self.articleKeyToSelect, place.articles.count == 1, place.articles.first?.key == keyToSelect {
                    // hacky workaround for now
                    self.deselectAllAnnotations()
                    self.placeToSelect = place
                    dispatchAfterDelayInSeconds(0.7, DispatchQueue.main, {
                        self.placeToSelect = nil
                        guard self.mapView.selectedAnnotations.count == 0 else {
                            return
                        }
                        self.selectArticlePlace(place)
                    })
                    self.articleKeyToSelect = nil
                }
            }
            
            //check for identical place already on the map
            if let place = annotationsToRemove.removeValue(forKey: identifier) {
                checkAndSelect(place)
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
                    guard let key = article.key,
                        let previousPlace = previousPlaceByArticle[key] else {
                            continue
                    }
                    
                    guard previousPlace.articles.count < groupCount else {
                            nextCoordinate = coordinate
                            coordinate = previousPlace.coordinate
                        break
                    }
                    
                    guard annotationsToRemove.removeValue(forKey: previousPlace.identifier) != nil else {
                        continue
                    }
                    
                    let placeView = mapView.view(for: previousPlace)
                    taskGroup.enter()
                    UIView.animate(withDuration:animationDuration, delay: 0, options: [], animations: {
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
            
            checkAndSelect(place)
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
        let articleURLToSelect = currentSearch?.searchResult?.articleURL(forSiteURL: siteURL) ?? searchResults.first?.articleURL(forSiteURL: siteURL)
        articleKeyToSelect = (articleURLToSelect as NSURL?)?.wmf_articleDatabaseKey
        var foundKey = false
        var keysToFetch: [String] = []
        var sort = 0
        for result in searchResults {
            guard let displayTitle = result.displayTitle,
                let articleURL = (siteURL as NSURL).wmf_URL(withTitle: displayTitle),
                let article = self.articleStore?.addPreview(with: articleURL, updatedWith: result),
                let _ = article.quadKey,
                let articleKey = article.key else {
                    continue
            }
            article.placesSortOrder = NSNumber(value: sort)
            if articleKeyToSelect != nil && articleKeyToSelect == articleKey {
                foundKey = true
            }
            keysToFetch.append(articleKey)
            sort += 1
        }
        
        if !foundKey, let keyToFetch = articleKeyToSelect, let URL = articleURLToSelect, let searchResult = currentSearch?.searchResult {
            articleStore.addPreview(with: URL, updatedWith: searchResult)
            keysToFetch.append(keyToFetch)
        }

        let request = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: "key in %@", keysToFetch)
        request.sortDescriptors = [NSSortDescriptor(key: "placesSortOrder", ascending: true)]
        articleFetchedResultsController = NSFetchedResultsController<WMFArticle>(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func updatePlaces() {
        listView.reloadData()
        currentGroupingPrecision = 0
        regroupArticlesIfNecessary(forVisibleRegion: mapRegion ?? mapView.region)
    }
    
    
    // ArticlePopoverViewControllerDelegate
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction action: WMFArticleAction) {
        perform(action: action, onArticle: articlePopoverViewController.article)
    }
    
    func perform(action: WMFArticleAction, onArticle article: WMFArticle) {
        guard let url = article.url else {
            return
        }

        switch action {
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
            let topNearbySuggestion = PlaceSearch(type: .top, sortStyle: .links, string: nil, region: nil, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles"), searchResult: nil)
            
            var suggestedSearches = [topNearbySuggestion]
            var recentSearches: [PlaceSearch] = []
            do {
                let moc = dataStore.viewContext
                if try moc.count(for: fetchRequestForSavedArticles) > 0 {
                    let saved = PlaceSearch(type: .saved, sortStyle: .none, string: nil, region: nil, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-saved-articles"), searchResult: nil)
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
        
        let currentStringSuggeston = PlaceSearch(type: .text, sortStyle: .links, string: currentSearchString, region: nil, localizedDescription: currentSearchString, searchResult: nil)
        searchSuggestionController.searches = [[], [], [currentStringSuggeston], completions]
    }
    
    func handleCompletion(searchResults: [MWKSearchResult]) -> [PlaceSearch] {
        var set = Set<String>()
        let completions = searchResults.flatMap { (result) -> PlaceSearch? in
            guard let location = result.location,
                let dimension = result.geoDimension?.doubleValue,
                let title = result.displayTitle,
                let url = (self.siteURL as NSURL).wmf_URL(withTitle: title),
                let key = (url as NSURL).wmf_articleDatabaseKey,
                !set.contains(key) else {
                    return nil
            }
            set.insert(key)
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, dimension, dimension)
            return PlaceSearch(type: .location, sortStyle: .links, string: nil, region: region, localizedDescription: result.displayTitle, searchResult: result)
        }
        updateSearchSuggestions(withCompletions: completions)
        return completions
    }

    
    func updateSearchCompletionsFromSearchBarText() {
        guard let text = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines), text != "" else {
            updateSearchSuggestions(withCompletions: [])
            return
        }
        searchFetcher.fetchArticles(forSearchTerm: text, siteURL: siteURL, resultLimit: 24, failure: { (error) in
            guard text == self.searchBar.text else {
                return
            }
            self.updateSearchSuggestions(withCompletions: [])
        }) { (searchResult) in
            guard text == self.searchBar.text else {
                return
            }
            
            let completions = self.handleCompletion(searchResults: searchResult.results ?? [])
            guard completions.count < 10 else {
                return
            }
            
            let center = self.mapView.userLocation.coordinate
            let region = CLCircularRegion(center: center, radius: 40075000, identifier: "world")
            self.locationSearchFetcher.fetchArticles(withSiteURL: self.siteURL, in: region, matchingSearchTerm: text, sortStyle: .links, resultLimit: 24, completion: { (locationSearchResults) in
                guard text == self.searchBar.text else {
                    return
                }
                var combinedResults: [MWKSearchResult] = searchResult.results ?? []
                let newResults = locationSearchResults.results as [MWKSearchResult]
                combinedResults.append(contentsOf: newResults)
                let _ = self.handleCompletion(searchResults: combinedResults)
            }) { (error) in
                guard text == self.searchBar.text else {
                    return
                }
            }
        }
    }
    
    var searchSuggestionsHidden = true {
        didSet {
            searchSuggestionView.isHidden = searchSuggestionsHidden
            segmentedControl.isEnabled = searchSuggestionsHidden
        }
    }
    
    // UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let type = currentSearch?.type, type != .text {
            searchBar.text = nil
        }
        searchSuggestionsHidden = false
        updateSearchSuggestions(withCompletions: [])
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
        currentSearch = PlaceSearch(type: .text, sortStyle: .links, string: searchBar.text, region: nil, localizedDescription: searchBar.text, searchResult: nil)
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchSuggestionsHidden = true
    }
    
    //UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return articleFetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articleFetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFNearbyArticleTableViewCell.identifier(), for: indexPath) as? WMFNearbyArticleTableViewCell else {
            return UITableViewCell()
        }
        
        let article = articleFetchedResultsController.object(at: indexPath)
        cell.titleText = article.displayTitle
        cell.descriptionText = article.wikidataDescription
        cell.setImageURL(article.thumbnailURL)
        
        update(userLocation: mapView.userLocation, onLocationCell: cell, withArticle: article)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let article = articleFetchedResultsController.object(at: indexPath)
        let title = article.savedDate == nil ? localizedStringForKeyFallingBackOnEnglish("action-save") : localizedStringForKeyFallingBackOnEnglish("action-unsave")
        let saveForLaterAction = UITableViewRowAction(style: .default, title: title) { (action, indexPath) in
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                let article = self.articleFetchedResultsController.object(at: indexPath)
                self.perform(action: .save, onArticle: article)
            })
            tableView.setEditing(false, animated: true)
            CATransaction.commit()
        }
        saveForLaterAction.backgroundColor = UIColor.wmf_darkBlueTint()
        
        let shareAction = UITableViewRowAction(style: .default, title: localizedStringForKeyFallingBackOnEnglish("action-share")) { (action, indexPath) in
            tableView.setEditing(false, animated: true)
            let article = self.articleFetchedResultsController.object(at: indexPath)
            self.perform(action: .share, onArticle: article)
        }
        shareAction.backgroundColor = UIColor.wmf_blueTint()
        return [saveForLaterAction, shareAction]
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
        let article = articleFetchedResultsController.object(at: indexPath)
        perform(action: .read, onArticle: article)
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
    
    func updateUserLocationAnnotationViewHeading(_ heading: CLHeading) {
        guard let view = mapView.view(for: mapView.userLocation) as? UserLocationAnnotationView else {
            return
        }
        view.isHeadingArrowVisible = heading.headingAccuracy > 0 && heading.headingAccuracy < 90
        view.heading = heading.trueHeading
    }
    
    func zoomAndPanMapView(toLocation location: CLLocation) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 5000, 5000)
        mapRegion = region
        performDefaultSearch(withRegion: region)
    }
    
    var panMapToNextLocationUpdate = true
    
    func locationManager(_ controller: WMFLocationManager, didUpdate location: CLLocation) {
        guard panMapToNextLocationUpdate else {
            return
        }
        panMapToNextLocationUpdate = false
        zoomAndPanMapView(toLocation: location)
    }
    
    func locationManager(_ controller: WMFLocationManager, didReceiveError error: Error) {
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate heading: CLHeading) {
        updateUserLocationAnnotationViewHeading(heading)

    }
    
    func locationManager(_ controller: WMFLocationManager, didChangeEnabledState enabled: Bool) {
    }
    
    @IBAction func recenterOnUserLocation(_ sender: Any) {
        zoomAndPanMapView(toLocation: locationManager.location)
    }
    
    // NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updatePlaces()
    }
}

