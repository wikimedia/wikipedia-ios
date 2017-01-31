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
    let localizedDescription: String?
    let searchCompletion: MKLocalSearchCompletion?
}

protocol PlaceSearchSuggestionControllerDelegate: NSObjectProtocol {
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didSelectSearch search: PlaceSearch)
}

class PlaceSearchSuggestionController: NSObject, UITableViewDataSource, UITableViewDelegate {
    static let cellReuseIdentifier = "org.wikimedia.places"
    
    var tableView: UITableView = UITableView() {
        didSet {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: PlaceSearchSuggestionController.cellReuseIdentifier)
            tableView.dataSource = self
            tableView.delegate = self
            tableView.reloadData()
        }
    }
    
    var searches: [[PlaceSearch]] = [[],[],[],[]]{
        didSet {
            tableView.reloadData()
        }
    }
    
    weak var delegate: PlaceSearchSuggestionControllerDelegate?
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return searches.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searches[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:  PlaceSearchSuggestionController.cellReuseIdentifier, for: indexPath)
        let search = searches[indexPath.section][indexPath.row]
        cell.textLabel?.text = search.localizedDescription
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let search = searches[indexPath.section][indexPath.row]
        delegate?.placeSearchSuggestionController(self, didSelectSearch: search)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard searches[section].count > 0 else {
            return nil
        }
        switch section {
        case 0:
            return localizedStringForKeyFallingBackOnEnglish("places-search-suggested-searches-header")
        case 1:
            return localizedStringForKeyFallingBackOnEnglish("places-search-recently-searched-header")
        default:
            return nil
        }
    }
}


class PlacesViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, ArticlePopoverViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate, PlaceSearchSuggestionControllerDelegate, WMFLocationManagerDelegate {

    @IBOutlet weak var redoSearchButton: UIButton!
    let nearbyFetcher = WMFLocationSearchFetcher()
    
    let localCompleter = MKLocalSearchCompleter()
    let globalCompleter = MKLocalSearchCompleter()
    
    let locationManager = WMFLocationManager.coarse()
    
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
    
    var currentSearch: PlaceSearch? {
        didSet {
            if let search = currentSearch {
                searchBar.text = search.localizedDescription
                performSearch(search)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup map view
        mapView.showsPointsOfInterest = false
        
        // Setup location manager
        locationManager.delegate = self
        locationManager.startMonitoringLocation()
        
        //Override UINavigationBar.appearance settings from WMFStyleManager
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = nil
        view.tintColor = UIColor.wmf_blueTint()
        redoSearchButton.backgroundColor = view.tintColor
        
        // Setup map/list toggle
        segmentedControl = UISegmentedControl(items: ["M", "L"])
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
        localCompleter.delegate = self
        globalCompleter.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectAllAnnotations()
    }

    func dismissPopover() {
        guard let _ = presentedViewController else {
            return
        }
        dismiss(animated: false, completion: nil)
    }
    
    func showRedoSearchButtonIfNecessary() {
        let visibleRegion = currentlyVisibleCircularCoordinateRegion
        guard let search = currentSearch else {
            return
        }
        let distance = CLLocation(latitude: visibleRegion.center.latitude, longitude: visibleRegion.center.longitude).distance(from: CLLocation(latitude: search.region.center.latitude, longitude: search.region.center.longitude))
        let radiusRatio = visibleRegion.radius/search.region.radius
        redoSearchButton.isHidden = !(radiusRatio > 1.33 || radiusRatio < 0.67 || distance/search.region.radius > 0.33)
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        dismissPopover()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regroupArticlesIfNecessary()
        showRedoSearchButtonIfNecessary()
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
            listView.reloadData()
        default:
            listView.isHidden = false
        }
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
        
        present(articleVC, animated: false) {
            
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
        redoSearchButton.isHidden = true
        
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
            self.wmf_showAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("empty-no-search-results-message"))
            self.searching = false
        }
    }
    
    @IBAction func redoSearch(_ sender: Any) {
        guard let search = currentSearch else {
            return
        }
        currentSearch = PlaceSearch(type: search.type, string: search.string, region: currentlyVisibleCircularCoordinateRegion, localizedDescription: search.string, searchCompletion: nil)
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
        
        let deltaLon = mapView.region.span.longitudeDelta
        let lowestPrecision = QuadKeyPrecision(deltaLongitude: deltaLon)
        let groupingPrecision = min(QuadKeyPrecision.maxPrecision, lowestPrecision + 3)
        
        guard groupingPrecision != currentGroupingPrecision else {
            return
        }
        
        guard let search = currentSearch else {
            return
        }
        
        let groupingDeltaLatitude = groupingPrecision.deltaLatitude
        let groupingDeltaLongitude = groupingPrecision.deltaLongitude
        
        let centerLat = search.region.center.latitude
        let centerLon = search.region.center.longitude
        let groupingDistanceLocation = CLLocation(latitude:centerLat + groupingDeltaLatitude, longitude: centerLon + groupingDeltaLongitude)
        let centerLocation = CLLocation(latitude:centerLat, longitude: centerLon)
        let groupingDistance = groupingDistanceLocation.distance(from: centerLocation)
        
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
        listView.reloadData()
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
    
    // Search completions
    
    func updateSearchSuggestions(withCompletions completions: [PlaceSearch]) {
        guard let currentSearchString = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines), currentSearchString != "" || completions.count > 0 else {
            let topNearbySuggestion = PlaceSearch(type: .top, string: nil, region: currentlyVisibleCircularCoordinateRegion, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby"), searchCompletion: nil)
            searchSuggestionController.searches = [[topNearbySuggestion], [], [], []]
            return
        }
        
        let currentStringSuggeston = PlaceSearch(type: .text, string: currentSearchString, region: currentlyVisibleCircularCoordinateRegion, localizedDescription: currentSearchString, searchCompletion: nil)
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
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchSuggestions(withCompletions: searchSuggestionController.searches[3])
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(updateSearchCompletionsFromSearchBarText), with: nil, afterDelay: 0.2)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        currentSearch = PlaceSearch(type: .text, string: searchBar.text, region: currentlyVisibleCircularCoordinateRegion, localizedDescription: searchBar.text, searchCompletion: nil)
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
            let search = PlaceSearch(type: .location, string: result.title, region: currentlyVisibleCircularCoordinateRegion, localizedDescription: result.title, searchCompletion: result)
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
    
    // WMFLocationManagerDelegate
    
    func locationManager(_ controller: WMFLocationManager, didUpdate location: CLLocation) {
        guard currentSearch == nil else {
            return
        }
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 5000, 5000)
        mapView.setRegion(region, animated: true)
        let searchRegion = CLCircularRegion(center: location.coordinate, radius: 5000, identifier: "")
        currentSearch = PlaceSearch(type: .top, string: nil, region: searchRegion, localizedDescription: localizedStringForKeyFallingBackOnEnglish("places-search-top-articles-nearby"), searchCompletion: nil)
    }
    
    func locationManager(_ controller: WMFLocationManager, didReceiveError error: Error) {
        
    }
    
    func locationManager(_ controller: WMFLocationManager, didUpdate heading: CLHeading) {
        
    }
    
    func locationManager(_ controller: WMFLocationManager, didChangeEnabledState enabled: Bool) {
        
    }
}

