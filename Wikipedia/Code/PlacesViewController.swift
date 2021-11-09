import UIKit
import WMF
import CocoaLumberjackSwift

import MapKit

@objc(WMFPlacesViewController)
class PlacesViewController: ViewController, UISearchBarDelegate, ArticlePopoverViewControllerDelegate, PlaceSearchSuggestionControllerDelegate, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate, ArticlePlaceViewDelegate, UIGestureRecognizerDelegate, HintPresenting {

    fileprivate var mapView: MapView!

    @IBOutlet weak var mapContainerView: UIView!
    
    @IBOutlet weak var redoSearchButton: UIButton!
    @IBOutlet weak var didYouMeanButton: UIButton!

    var fakeProgressController: FakeProgressController!
    @IBOutlet weak var recenterOnUserLocationButton: UIButton!
    @IBOutlet weak var listAndSearchOverlayContainerView: RoundedCornerView!
    @IBOutlet weak var listAndSearchOverlaySliderSeparator: UIView!

    @IBOutlet weak var listAndSearchOverlayBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var listAndSearchOverlayHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var listAndSearchOverlaySliderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var listAndSearchOverlaySliderView: UIView!
    @IBOutlet weak var listContainerView: UIView!
    var listViewController: ArticleLocationCollectionViewController!
    @IBOutlet weak var searchSuggestionView: UITableView!
    @IBOutlet var emptySearchOverlayView: PlaceSearchEmptySearchOverlayView!
    
    @objc public var dataStore: MWKDataStore! {
        didSet {
            wikidataFetcher =  WikidataFetcher(session: dataStore.session, configuration: dataStore.configuration)
        }
    }
    fileprivate var wikidataFetcher: WikidataFetcher!
    fileprivate let locationSearchFetcher = WMFLocationSearchFetcher()
    fileprivate let searchFetcher = WMFSearchFetcher()
    fileprivate let locationManager = LocationManager()
    fileprivate let animationDuration = 0.6
    fileprivate let animationScale = CGFloat(0.6)
    fileprivate let popoverFadeDuration = 0.25
    fileprivate let searchHistoryCountLimit = 15
    fileprivate var searchSuggestionController: PlaceSearchSuggestionController!

    fileprivate var siteURL: URL {
        return MWKDataStore.shared().primarySiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    }
    
    fileprivate var currentGroupingPrecision: QuadKeyPrecision = 1
    fileprivate var selectedArticlePopover: ArticlePopoverViewController?
    fileprivate var selectedArticleAnnotationView: MapAnnotationView?
    fileprivate var selectedArticleKey: String?
    fileprivate var articleKeyToSelect: String?
    fileprivate var currentSearchRegion: MKCoordinateRegion?
    fileprivate var performDefaultSearchOnNextMapRegionUpdate = false
    fileprivate var isMovingToRegion = false

    fileprivate var previouslySelectedArticlePlaceIdentifier: Int?
    fileprivate var didYouMeanSearch: PlaceSearch?
    fileprivate var searching: Bool = false
    // SINGLETONTODO
    fileprivate let imageController = MWKDataStore.shared().cacheController.imageCache

    fileprivate var _displayCountForTopPlaces: Int?
    fileprivate var displayCountForTopPlaces: Int {
        get {
            switch (self.currentSearchFilter) {
            case .top:
                return articleFetchedResultsController?.fetchedObjects?.count ?? 0
            case .saved:
                return _displayCountForTopPlaces ?? 0
            }
        }
    }

    lazy fileprivate var placeSearchService: PlaceSearchService! = {
        return PlaceSearchService(dataStore: self.dataStore)
    }()
    
    // MARK: - View Lifecycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        title = CommonStrings.placesTabTitle
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = UIRectEdge.all
    }

    // MARK - Search

    lazy var searchBarContainerView: UIView = {
        let searchBarContainerView = UIView()
        searchBarStackView.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainerView.addSubview(searchBarStackView)
        let leading = searchBarContainerView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: searchBarStackView.leadingAnchor)
        let trailing = searchBarContainerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: searchBarStackView.trailingAnchor)
        let top = searchBarContainerView.topAnchor.constraint(equalTo: searchBarStackView.topAnchor)
        let bottom = searchBarContainerView.bottomAnchor.constraint(equalTo: searchBarStackView.bottomAnchor)
        searchBarContainerView.addConstraints([leading, trailing, top, bottom])
        return searchBarContainerView
    }()

    lazy var searchBarStackView: UIStackView = {
        let searchBarStackView = UIStackView()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        mapListToggleContainer.translatesAutoresizingMaskIntoConstraints = false
        searchBarStackView.axis = .horizontal
        searchBarStackView.alignment = .center
        searchBarStackView.distribution = .fill
        searchBarStackView.spacing = 10
        searchBarStackView.addArrangedSubview(searchBar)
        searchBarStackView.addArrangedSubview(mapListToggleContainer)
        return searchBarStackView
    }()

    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = WMFLocalizedString("places-search-default-text", value:"Search Places", comment:"Placeholder text that displays where is there no current place search {{Identical|Search}}")
        searchBar.delegate = self
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = false
        return searchBar
    }()
    
    lazy var mapListToggleContainer: UIView = {
        let mapListToggleContainer = UIView()
        mapListToggleContainer.wmf_addSubview(mapListToggle, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)) // hax: alignment
        return mapListToggleContainer
    }()

    lazy var mapListToggle: UISegmentedControl = {
        let mapListToggle = UISegmentedControl()
        let map = #imageLiteral(resourceName: "places-map")
        let list = #imageLiteral(resourceName: "places-list")
        map.accessibilityLabel = WMFLocalizedString("places-accessibility-show-as-map", value:"Show as map", comment:"Accessibility label for the show as map toggle item")
        list.accessibilityLabel = WMFLocalizedString("places-accessibility-show-as-list", value:"Show as list", comment:"Accessibility label for the show as list toggle item")
        mapListToggle.insertSegment(with: map, at: 0, animated: false)
        mapListToggle.insertSegment(with: list, at: 1, animated: false)
        mapListToggle.selectedSegmentIndex = 0
        mapListToggle.addTarget(self, action: #selector(updateViewModeFromSegmentedControl), for: .valueChanged)
        return mapListToggle
    }()
    
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("places-filter-button-title", value: "Filter", comment: "Title for button that allows users to filter places"), style: .plain, target: self, action: #selector(filterButtonPressed(_:)))
        navigationBar.addUnderNavigationBarView(searchBarContainerView)
        navigationBar.displayType = .largeTitle
        navigationBar.delegate = self
        navigationBar.isBarHidingEnabled = false

        listViewController = ArticleLocationCollectionViewController(articleURLs: [], dataStore: dataStore, contentGroup: nil, theme: theme)
        addChild(listViewController)
        listViewController.view.frame = listContainerView.bounds
        listViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        listContainerView.addSubview(listViewController.view)
        listViewController.didMove(toParent: self)
        
        let mapViewFrame = mapContainerView.bounds
        mapView = MapView(frame: mapViewFrame)
        mapView.delegate = self

        // Setup map view
        mapView.mapType = .standard
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsScale = false
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        mapContainerView.wmf_addSubviewWithConstraintsToEdges(mapView)

        fakeProgressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)

        // Setup location manager
        locationManager.delegate = self
    
        // Setup Redo search button
        redoSearchButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        redoSearchButton.setTitleColor(.white, for: .normal)
        redoSearchButton.setTitle(WMFLocalizedString("places-search-this-area", value:"Results in this area", comment:"A button title that indicates the search will be redone in the visible area"), for: .normal)
        redoSearchButton.isHidden = true
        
        // Setup Did You Mean button
        didYouMeanButton.setTitleColor(.white, for: .normal)
        didYouMeanButton.isHidden = true
        didYouMeanButton.titleLabel?.adjustsFontSizeToFitWidth = true
        didYouMeanButton.titleLabel?.textAlignment = .center

        // Setup recenter button
        recenterOnUserLocationButton.accessibilityLabel = WMFLocalizedString("places-accessibility-recenter-map-on-user-location", value:"Recenter on your location", comment:"Accessibility label for the recenter map on the user's location button")
        recenterOnUserLocationButton.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 1)

        listAndSearchOverlayContainerView.corners = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        
        // Setup search suggestions
        searchSuggestionController = PlaceSearchSuggestionController()
        searchSuggestionController.tableView = searchSuggestionView
        searchSuggestionController.delegate = self

        super.viewDidLoad()

        let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGR.delegate = self
        view.addGestureRecognizer(panGR)
        overlaySliderPanGestureRecognizer = panGR

        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Update saved places locations
        placeSearchService.fetchSavedArticles(searchString: nil)
        
        super.viewWillAppear(animated)

        if isFirstAppearance {
            isFirstAppearance = false
            if UIAccessibility.isVoiceOverRunning {
                viewMode = .list
                mapListToggle.selectedSegmentIndex = 1
            } else {
                viewMode = .map
            }
        }

        constrainButtonsToNavigationBar()
        
        let defaults = UserDefaults.standard
        if !defaults.wmf_placesHasAppeared() {
            defaults.wmf_setPlacesHasAppeared(true)
        }

        /// Terrible hack to make back button text appropriate for iOS 14 - need to set the title on `WMFAppViewController`. For all app tabs, this is set in `viewWillAppear`.
        (parent as? WMFAppViewController)?.navigationItem.backButtonTitle = title
        
        guard locationManager.isAuthorized else {
            if !defaults.wmf_placesDidPromptForLocationAuthorization() {
                defaults.wmf_setPlacesDidPromptForLocationAuthorization(true)
                promptForLocationAccess()
            } else {
                performDefaultSearchOnNextMapRegionUpdate = currentSearch == nil
            }
            return
        }
        
        locationManager.startMonitoringLocation()
        mapView.showsUserLocation = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillHideNotification, object: nil)
        locationManager.stopMonitoringLocation()
        mapView.showsUserLocation = false
    }

    private func constrainButtonsToNavigationBar() {
        let recenterOnUserLocationButtonTopConstraint = recenterOnUserLocationButton.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 17)
        let redoSearchButtonTopConstraint = redoSearchButton.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 17)
        let didYouMeanButtonTopConstraint = didYouMeanButton.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 17)

        NSLayoutConstraint.activate([recenterOnUserLocationButtonTopConstraint, redoSearchButtonTopConstraint, didYouMeanButtonTopConstraint])
    }
    
    func selectVisibleArticle(articleKey: String) -> Bool {
        let annotations = mapView.visibleAnnotations
        for annotation in annotations {
            guard let place = annotation as? ArticlePlace,
                place.articles.count == 1,
                let article = place.articles.first,
                article.key == articleKey else {
                    continue
            }
            selectArticlePlace(place)
            return true
        }
        return false
    }

    func selectVisibleKeyToSelectIfNecessary() {
        guard !isMovingToRegion, countOfAnimatingAnnotations == 0, let keyToSelect = articleKeyToSelect, viewMode == .map else {
            return
        }
        guard selectVisibleArticle(articleKey: keyToSelect) else {
            return
        }
        articleKeyToSelect = nil

    }

    fileprivate func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let sections = articleFetchedResultsController?.sections,
            indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].numberOfObjects else {
                return nil
        }
        return articleFetchedResultsController?.object(at: indexPath)
    }

    public func logListViewImpression(forIndexPath indexPath: IndexPath) {

    }

    public func logListViewImpressionsForVisibleCells() {
        for indexPath in listViewController.collectionView.indexPathsForVisibleItems {
            logListViewImpression(forIndexPath: indexPath)
        }
    }
    
    func updateShouldShowAllImagesIfNecessary() {
        let visibleAnnotations = mapView.visibleAnnotations
        var visibleArticleCount = 0
        var visibleGroupCount = 0
        for annotation in visibleAnnotations {
            guard let place = annotation as? ArticlePlace else {
                continue
            }
            if place.articles.count == 1 {
                visibleArticleCount += 1
            } else {
                visibleGroupCount += 1
            }
        }
        let articlesPerSquarePixel = CGFloat(visibleArticleCount) / mapView.bounds.width * mapView.bounds.height
        let shouldShowAllImages = visibleGroupCount == 0 && visibleArticleCount > 0 && articlesPerSquarePixel < 40
        set(shouldShowAllImages: shouldShowAllImages)
    }
    
    func set(shouldShowAllImages: Bool) {
        if shouldShowAllImages != showingAllImages {
            for annotation in mapView.annotations {
                guard let view = mapView.view(for: annotation) as? ArticlePlaceView else {
                    continue
                }
                view.set(alwaysShowImage: shouldShowAllImages, animated: true)
            }
            showingAllImages = shouldShowAllImages
        }
    }
    
    var countOfAnimatingAnnotations = 0 {
        didSet {
            if countOfAnimatingAnnotations == 0 {
                selectVisibleKeyToSelectIfNecessary()
            }
        }
    }

    // MARKL - Filtering

    // hax
    private func setCheckmark(for alertAction: UIAlertAction, in alertController: UIAlertController) {
        let key = "checked"
        for action in alertController.actions {
            action.setValue(false, forKey: key)
        }
        alertAction.setValue(true, forKey: key)
    }

    @objc private func filterButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: WMFLocalizedString("places-filter-articles-action-sheet-title", value: "Filter articles", comment: "Title for action sheet that allows users to filter Places articles"), message: nil, preferredStyle: .actionSheet)
        let topReadArticlesAction = UIAlertAction(title: WMFLocalizedString("places-filter-top-read-articles", value: "Top read articles", comment: "Title for action that allows users to filter top read articles"), style: .default) { _ in
            self.currentSearchFilter = .top
        }

        let savedArticlesAction = UIAlertAction(title: WMFLocalizedString("places-filter-saved-articles", value:"Saved articles", comment:"Title of places search filter that searches saved articles"), style: .default) { _ in
            self.currentSearchFilter = .saved
        }
        alertController.addAction(topReadArticlesAction)
        alertController.addAction(savedArticlesAction)
        let checkedAction = currentSearchFilter == .top ? topReadArticlesAction : savedArticlesAction
        self.setCheckmark(for: checkedAction, in: alertController)
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }

    // MARK: - Map Region
    
    fileprivate func region(thatFits regionToFit: MKCoordinateRegion) -> MKCoordinateRegion {
        var region = mapView.regionThatFits(regionToFit)
        
        if region.span.latitudeDelta == 0 || region.span.longitudeDelta == 0 ||
           region.span.latitudeDelta.isNaN || region.span.longitudeDelta.isNaN ||
           region.span.latitudeDelta.isInfinite || region.span.longitudeDelta.isInfinite {
            region = regionToFit
        }

        return region
    }
    
    fileprivate var _mapRegion: MKCoordinateRegion?
    
    fileprivate var mapRegion: MKCoordinateRegion? {
        set {
            guard let value = newValue else {
                _mapRegion = nil
                return
            }
            
            let region = self.region(thatFits: value)
            _mapRegion = region
            
            regroupArticlesIfNecessary(forVisibleRegion: region)
            updateViewIfMapMovedSignificantly(forVisibleRegion: region)
            
            let mapViewRegion = mapView.region
            guard mapViewRegion.center.longitude != region.center.longitude || mapViewRegion.center.latitude != region.center.latitude || mapViewRegion.span.longitudeDelta != region.span.longitudeDelta || mapViewRegion.span.latitudeDelta != region.span.latitudeDelta else {
                selectVisibleKeyToSelectIfNecessary()
                return
            }
            
            guard !isViewModeOverlay || overlayState == .min else {
                let factor = UIApplication.shared.wmf_isRTL ? 0.1 : -0.1
                let adjustedCenter = CLLocationCoordinate2DMake(region.center.latitude, region.center.longitude + factor * region.span.latitudeDelta)
                let adjustedRegion = MKCoordinateRegion(center: adjustedCenter, span: region.span)
                mapView.setRegion(adjustedRegion, animated: true)
                return
            }

            mapView.setRegion(region, animated: true)
        }
        
        get {
            return _mapRegion
        }
    }
    
    func region(thatFits articles: [WMFArticle]) -> MKCoordinateRegion {
        let coordinates: [CLLocationCoordinate2D] =  articles.compactMap({ (article) -> CLLocationCoordinate2D? in
            return article.coordinate
        })
        guard coordinates.count > 1 else {
            return coordinates.wmf_boundingRegion(with: 10000)
        }
        
        let initialRegion = coordinates.wmf_boundingRegion(with: 50)
        return coordinates.wmf_boundingRegion(with: 0.25 * initialRegion.width)
    }
    
    // MARK: - Searching
    
    var currentSearch: PlaceSearch? {
        didSet {
            guard let search = currentSearch else {
                return
            }
            
            updateSearchBarText(forSearch: search)

            performSearch(search)
            
            switch search.type {
            case .nearby:
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
    
    func performDefaultSearchIfNecessary(withRegion region: MKCoordinateRegion?) {
        guard currentSearch == nil else {
            return
        }
        performDefaultSearch(withRegion: region)
    }
    
    func isDefaultSearch(_ placeSearch: PlaceSearch) -> Bool {
        return placeSearch.type == .location && placeSearch.string == nil && placeSearch.searchResult == nil && placeSearch.origin == .system
    }
    
    func performDefaultSearch(withRegion region: MKCoordinateRegion?) {
        currentSearch = PlaceSearch(filter: currentSearchFilter, type: .location, origin: .system, sortStyle: .links, string: nil, region: region, localizedDescription: WMFLocalizedString("places-search-top-articles", value:"All top articles", comment:"A search suggestion for top articles"), searchResult: nil)
    }
    
    var articleFetchedResultsController: NSFetchedResultsController<WMFArticle>? {
        didSet {
            oldValue?.delegate = nil
            for article in oldValue?.fetchedObjects ?? [] {
                article.placesSortOrder = NSNumber(integerLiteral: 0)
            }
            do {
                try dataStore.viewContext.save()
                try articleFetchedResultsController?.performFetch()
            } catch let fetchError {
                DDLogError("Error fetching articles for places: \(fetchError)")
            }
            updatePlaces()
            articleFetchedResultsController?.delegate = self
        }
    }
    
    func isDistanceSignificant(betweenRegion searchRegion: MKCoordinateRegion, andRegion visibleRegion: MKCoordinateRegion) -> Bool {
        let distance = CLLocation(latitude: visibleRegion.center.latitude, longitude: visibleRegion.center.longitude).distance(from: CLLocation(latitude: searchRegion.center.latitude, longitude: searchRegion.center.longitude))
        
        let searchWidth = searchRegion.width
        let searchHeight = searchRegion.height
        let searchRegionMinDimension = min(searchWidth, searchHeight)
        
        guard searchRegionMinDimension > 0 else {
            return distance > 1000
        }
       
        let isDistanceSignificant = distance/searchRegionMinDimension > 0.33
        guard !isDistanceSignificant else {
            return true
        }
        
        let visibleWidth = visibleRegion.width
        let visibleHeight = visibleRegion.height
        
        guard searchWidth > 0, visibleWidth > 0, visibleHeight > 0, searchHeight > 0 else {
            return false
        }
        
        let widthRatio = visibleWidth/searchWidth
        let heightRatio = visibleHeight/searchHeight
        let ratio = min(widthRatio, heightRatio)
        return ratio > 1.33 || ratio < 0.67
    }

    func updateViewIfMapMovedSignificantly(forVisibleRegion visibleRegion: MKCoordinateRegion) {
        guard let searchRegion = currentSearchRegion else {
            redoSearchButton.isHidden = true
            return
        }
        
        let regionThatFits = region(thatFits: searchRegion)
        let movedSignificantly = isDistanceSignificant(betweenRegion: regionThatFits, andRegion: visibleRegion)
        DDLogDebug("movedSignificantly=\(movedSignificantly)")
        
        // Update Redo Search Button
        redoSearchButton.isHidden = !(movedSignificantly)

        if (movedSignificantly) {
            // Update Did You Mean Button
            hideDidYouMeanButton()
            
            // Clear count for Top Places
            _displayCountForTopPlaces = nil
        }
    }
    
    func performSearch(_ search: PlaceSearch) {
        guard !searching else {
            return
        }
        
        guard search.type != .nearby else {
            currentSearch = nil // will cause the default search to perform after re-centering
            recenterOnUserLocation(self)
            return
        }
        
        let done = {
            self.searching = false
            self.fakeProgressController.finish()
        }
        
        searching = true
        redoSearchButton.isHidden = true
        deselectAllAnnotations()
        updateSavedPlacesCountInCurrentMapRegionIfNecessary()
        hideDidYouMeanButton()
        
        let siteURL = search.siteURL ?? self.siteURL
        let region = search.region ?? mapRegion ?? mapView.region
        currentSearchRegion = region

        if (search.filter == .top && search.type == .location) {
            if (search.needsWikidataQuery) {
                performWikidataQuery(forSearch: search)
                return
            }
        }
        
        if let currentMapRegion = mapRegion, isDistanceSignificant(betweenRegion: region, andRegion: currentMapRegion) {
            mapRegion = region
        } else if mapRegion == nil {
            mapRegion = region
        }
                
        self.fakeProgressController.start()
        
        switch search.filter {
        case .saved:
            let moc = dataStore.viewContext
            placeSearchService.performSearch(search, defaultSiteURL: siteURL, region: region, completion: { (result) in
                defer { done() }
                
                guard result.error == nil else {
                    DDLogError("Error fetching saved articles: \(result.error?.localizedDescription ?? "unknown error")")
                    return
                }
                guard let request = result.fetchRequest else {
                    DDLogError("Error fetching saved articles: fetchRequest was nil")
                    return
                }
                
                self.articleFetchedResultsController = NSFetchedResultsController<WMFArticle>(fetchRequest: request, managedObjectContext: self.dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
                
                do {
                    let articlesToShow = try moc.fetch(request)
                    self.articleKeyToSelect = articlesToShow.first?.key
                    if !articlesToShow.isEmpty {
                        if (self.currentSearch?.region == nil) {
                            self.currentSearchRegion = self.region(thatFits: articlesToShow)
                            self.mapRegion = self.currentSearchRegion
                        }
                    }
                    if articlesToShow.isEmpty {
                        self.wmf_showAlertWithMessage(WMFLocalizedString("places-no-saved-articles-have-location", value:"None of your saved articles have location information", comment:"Indicates to the user that none of their saved articles have location information"))
                    }
                } catch let error {
                    DDLogError("Error fetching saved articles: \(error.localizedDescription)")
                }
            })

        case .top:
            placeSearchService.performSearch(search, defaultSiteURL: siteURL, region: region, completion: { (result) in
                defer { done() }
                
                guard result.error == nil else {
                    if let error = result.error {
                        WMFAlertManager.sharedInstance.showWarningAlert(result.error!.localizedDescription, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                        
                        let nserror = error as NSError
                        if (nserror.code == Int(WMFLocationSearchErrorCode.noResults.rawValue)) {
                            let completions = self.searchSuggestionController.searches[PlaceSearchSuggestionController.completionSection]
                            if !completions.isEmpty {
                                self.showDidYouMeanButton(search: completions[0])
                            }
                        }
                    } else {
                        WMFAlertManager.sharedInstance.showWarningAlert(CommonStrings.unknownError, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                    }
                    return
                }
                
                guard let locationResults = result.locationResults else {
                    assertionFailure("no error and missing location results")
                    return
                }
                
                self.updatePlaces(withSearchResults: locationResults)
            })
        }
    }
    
    func showDidYouMeanButton(search: PlaceSearch) {
        guard let description = search.localizedDescription else {
            DDLogError("Could not show Did You Mean button = no description for search:\n\(search)")
            return
        }
        
        DDLogDebug("Did you mean '\(String(describing: search.localizedDescription))'?")
        self.didYouMeanSearch = search
        self.didYouMeanButton.isHidden = false
        
        let title = String.localizedStringWithFormat(WMFLocalizedString("places-search-did-you-mean", value:"Did you mean %1$@?", comment:"Title displayed on a button shown when the current search has no results. %1$@ is replaced by the short description of the location of the most likely correction."), description)
        
        let buttonFont = redoSearchButton.titleLabel?.font
        let italicsFont = UIFont.italicSystemFont(ofSize: buttonFont?.pointSize ?? 15.0)
        let nsTitle = title as NSString
        let attributedTitle = NSMutableAttributedString(string: title)
        let descriptionRange = nsTitle.range(of: description)
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: italicsFont, range: descriptionRange)
        self.didYouMeanButton.setAttributedTitle(attributedTitle, for: .normal)
    }
    
    func hideDidYouMeanButton() {
        didYouMeanButton.isHidden = true
        didYouMeanSearch = nil
    }

    func performWikidataQuery(forSearch search: PlaceSearch) {
        let fail = {
            DispatchQueue.main.async {
                self.searching = false
                var newSearch = search
                newSearch.needsWikidataQuery = false
                self.currentSearch = newSearch
            }
        }
        guard let articleURL = search.searchResult?.articleURL(forSiteURL: siteURL) else {
            fail()
            return
        }
        
        wikidataFetcher.wikidataBoundingRegion(forArticleURL: articleURL, failure: { (error) in
            DDLogError("Error fetching bounding region from Wikidata: \(error)")
            fail()
        }, success: { (region) in
            DispatchQueue.main.async {
                self.searching = false
                var newSearch = search
                newSearch.needsWikidataQuery = false
                newSearch.region = region
                self.currentSearch = newSearch
            }
        })
    }
    
    func updatePlaces(withSearchResults searchResults: [MWKSearchResult]) {
        if let searchSuggestionArticleURL = currentSearch?.searchResult?.articleURL(forSiteURL: siteURL),
            let searchSuggestionArticleKey = searchSuggestionArticleURL.wmf_databaseKey { // the user tapped an article in the search suggestions list, so we should select that
            articleKeyToSelect = searchSuggestionArticleKey
        } else if currentSearch?.filter == .top {
            if let centerCoordinate = currentSearch?.region?.center ?? mapRegion?.center {
                let center = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
                var minDistance = CLLocationDistance(Double.greatestFiniteMagnitude)
                var resultToSelect: MWKSearchResult?
                for result in searchResults {
                    guard let location = result.location else {
                        continue
                    }
                    let distance = location.distance(from: center)
                    if distance < minDistance {
                        minDistance = distance
                        resultToSelect = result
                    }
                }
                let resultURL = resultToSelect?.articleURL(forSiteURL: siteURL)
                articleKeyToSelect = resultURL?.wmf_databaseKey
            } else {
                let firstResultURL = searchResults.first?.articleURL(forSiteURL: siteURL)
                articleKeyToSelect = firstResultURL?.wmf_databaseKey
            }
        }
        
        var foundKey = false
        var keysToFetch: [String] = []
        var sort = 1
        for result in searchResults {
            guard let articleURL = result.articleURL(forSiteURL: siteURL),
                let article = self.dataStore.viewContext.fetchOrCreateArticle(with: articleURL, updatedWith: result),
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
        
        if !foundKey, let keyToFetch = articleKeyToSelect, let URL = URL(string: keyToFetch), let searchResult = currentSearch?.searchResult {
            dataStore.viewContext.fetchOrCreateArticle(with: URL, updatedWith: searchResult)
            keysToFetch.append(keyToFetch)
        }
        
        let request = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: "key in %@", keysToFetch)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.placesSortOrder, ascending: true)]
        articleFetchedResultsController = NSFetchedResultsController<WMFArticle>(fetchRequest: request, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func updatePlaces() {
        let articleURLs = articleFetchedResultsController?.fetchedObjects?.compactMap({ (article) -> URL? in
            return article.url
        })
        listViewController.articleURLs = articleURLs ?? []
        currentGroupingPrecision = 0
        regroupArticlesIfNecessary(forVisibleRegion: mapRegion ?? mapView.region)
        if currentSearch?.region == nil { // this means the search was done in the curent map region and the map won't move
            selectVisibleKeyToSelectIfNecessary()
        }
    }
    
    func updateSavedPlacesCountInCurrentMapRegionIfNecessary() {
        guard _displayCountForTopPlaces == nil else {
            return
        }
        
        if let currentSearch = self.currentSearch, currentSearchFilter == .saved {
            var tempSearch = PlaceSearch(filter: .top, type: currentSearch.type, origin: .system, sortStyle: currentSearch.sortStyle, string: nil, region: mapView.region, localizedDescription: nil, searchResult: nil)
            tempSearch.needsWikidataQuery = false
            
            placeSearchService.performSearch(tempSearch, defaultSiteURL: siteURL, region: mapView.region, completion: { (searchResult) in
                guard let locationResults = searchResult.locationResults else {
                    return
                }
                DDLogDebug("got \(locationResults.count) top places!")
                self._displayCountForTopPlaces = locationResults.count
            })
        }
    }

    
    @IBAction func redoSearch(_ sender: Any) {
        guard let search = currentSearch else {
            return
        }
        
        redoSearchButton.isHidden = true
        
        if isDefaultSearch(search) || (search.type == .location && search.filter == .top) {
            performDefaultSearch(withRegion: mapView.region)
        } else {
            currentSearch = PlaceSearch(filter: currentSearchFilter, type: search.type, origin: .user, sortStyle: search.sortStyle, string: search.string, region: nil, localizedDescription: search.localizedDescription, searchResult: nil)
        }
    }
    
    @IBAction func didYouMean(_ sender: Any) {
        defer {
            hideDidYouMeanButton()
        }
        
        guard let search = self.didYouMeanSearch else {
            DDLogError("Did You Mean search is unset")
            return
        }
        
        performSearch(search)
    }
    
    // MARK: - Display Actions
    
    func deselectAllAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }
    
    var useOverlay: Bool {
        get {
            return traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
        }
    }
    
    func updateLayout(_ traitCollection: UITraitCollection, animated: Bool) {
        if useOverlay {
            switch viewMode {
            case .search:
                viewMode = .searchOverlay
            case .list:
                fallthrough
            case .map:
                viewMode = .listOverlay
            default:
                break
            }
        } else {
            switch viewMode {
            case .searchOverlay:
                viewMode = .search
            case .listOverlay:
                viewMode = .map
            default:
                break
            }
        }
    }
    
    enum ViewMode {
        case none
        case map
        case list
        case search
        case listOverlay
        case searchOverlay
    }
    
    fileprivate var overlaySliderPanGestureRecognizer: UIPanGestureRecognizer?
    
    var initialOverlayHeightForPan: CGFloat?
    
    let overlayMidHeight: CGFloat = 388
    var overlayMinHeight: CGFloat {
        get {
            return 100 + listAndSearchOverlaySliderHeightConstraint.constant
        }
    }
    var overlayMaxHeight: CGFloat {
        get {
            return view.bounds.size.height - listAndSearchOverlayContainerView.frame.minY - listAndSearchOverlayBottomConstraint.constant
        }
    }

    enum OverlayState {
        case min
        case mid
        case max
    }
    
    func set(overlayState: OverlayState, withVelocity velocity: CGFloat, animated: Bool) {
        let currentHeight = listAndSearchOverlayHeightConstraint.constant
        let newHeight: CGFloat
        switch overlayState {
        case .min:
            newHeight = overlayMinHeight
        case .max:
            newHeight = overlayMaxHeight
        default:
            newHeight = overlayMidHeight
        }
        let springVelocity = velocity / (newHeight - currentHeight)
        self.view.layoutIfNeeded()
        let animations = {
            self.listAndSearchOverlayHeightConstraint.constant = newHeight
            self.view.layoutIfNeeded()
        }
        let duration: TimeInterval = 0.5
        self.overlayState = overlayState
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: springVelocity, options: [.allowUserInteraction], animations: animations, completion: { (didFinish) in
            if overlayState == .max {
                self.listAndSearchOverlayHeightConstraint.isActive = false
                self.listAndSearchOverlayBottomConstraint.isActive = true
            } else {
                self.listAndSearchOverlayHeightConstraint.isActive = true
                self.listAndSearchOverlayBottomConstraint.isActive = false
            }
        })
    }
    
    var overlayState = OverlayState.mid
    
    
    @objc func handlePanGesture(_ panGR: UIPanGestureRecognizer) {
        let minHeight = overlayMinHeight
        let maxHeight = overlayMaxHeight
        let midHeight = overlayMidHeight
        switch panGR.state {
        case .possible:
            fallthrough
        case .began:
            fallthrough
        case .changed:
            let initialHeight: CGFloat
            if let height = initialOverlayHeightForPan {
                initialHeight = height
            } else {
                if (overlayState == .max) {
                    listAndSearchOverlayHeightConstraint.constant = listAndSearchOverlayContainerView.frame.height
                }
                initialHeight = listAndSearchOverlayHeightConstraint.constant
                initialOverlayHeightForPan = initialHeight
                listAndSearchOverlayHeightConstraint.isActive = true
                listAndSearchOverlayBottomConstraint.isActive = false
            }
            listAndSearchOverlayHeightConstraint.constant = max(minHeight, initialHeight + panGR.translation(in: view).y)
        case .ended:
            fallthrough
        case .failed:
            fallthrough
        case .cancelled:
            let currentHeight = listAndSearchOverlayHeightConstraint.constant
            let newState: OverlayState
            if currentHeight <= midHeight {
                let min: Bool = currentHeight - minHeight <= midHeight - currentHeight
                if min {
                    newState = .min
                } else {
                    newState = .mid
                }
            } else {
                let mid: Bool = currentHeight - midHeight <= maxHeight - currentHeight
                if mid {
                    newState = .mid
                } else {
                    newState = .max
                }
            }
            set(overlayState: newState, withVelocity: panGR.velocity(in: view).y, animated: true)
            initialOverlayHeightForPan = nil
            break
        @unknown default:
            break
        }
    }
    
    fileprivate func updateTraitBasedViewMode() {
        //forces an update
        let oldViewMode = self.viewMode
        self.viewMode = .none
        self.viewMode = oldViewMode
    }
    
    var isViewModeOverlay: Bool {
        get {
            return traitBasedViewMode == .listOverlay || traitBasedViewMode == .searchOverlay
        }
    }
    
    var traitBasedViewMode: ViewMode = .none {
        didSet {
            guard oldValue != traitBasedViewMode else {
                return
            }
            if oldValue == .search && viewMode != .search {
                UIView.animate(withDuration: 0.3) {
                    self.mapListToggleContainer.alpha = 1
                    self.mapListToggleContainer.isHidden = false
                    self.searchBarStackView.layoutIfNeeded()
                    self.searchBar.setShowsCancelButton(false, animated: true)
                }
            } else if oldValue != .search && viewMode == .search {
                UIView.animate(withDuration: 0.3) {
                    self.mapListToggleContainer.isHidden = true
                    self.mapListToggleContainer.alpha = 0
                    self.searchBarStackView.layoutIfNeeded()
                    self.searchBar.setShowsCancelButton(true, animated: true)
                }
            }
            switch traitBasedViewMode {
            case .listOverlay:
                deselectAllAnnotations()
                listViewController.updateLocationOnVisibleCells()
                logListViewImpressionsForVisibleCells()
                mapView.isHidden = false
                listContainerView.isHidden = false
                searchSuggestionView.isHidden = true
                listAndSearchOverlayContainerView.isHidden = false
                mapListToggleContainer.isHidden = true
                navigationBar.isInteractiveHidingEnabled = false
                listViewController.scrollView?.contentInsetAdjustmentBehavior = .automatic
            case .list:
                deselectAllAnnotations()
                listViewController.updateLocationOnVisibleCells()
                logListViewImpressionsForVisibleCells()
                emptySearchOverlayView.removeFromSuperview()
                mapView.isHidden = true
                listContainerView.isHidden = false
                searchSuggestionView.isHidden = true
                listAndSearchOverlayContainerView.isHidden = false
                navigationBar.isInteractiveHidingEnabled = true
                listViewController.scrollView?.contentInsetAdjustmentBehavior = .never
            case .searchOverlay:
                if overlayState == .min {
                    set(overlayState: .mid, withVelocity: 0, animated: true)
                }
                mapView.isHidden = false
                listContainerView.isHidden = true
                searchSuggestionView.isHidden = false
                listAndSearchOverlayContainerView.isHidden = false
                navigationBar.isInteractiveHidingEnabled = false
                searchSuggestionView.contentInsetAdjustmentBehavior = .automatic
                scrollView = nil
                searchSuggestionController.navigationBarHider = nil
            case .search:
                mapView.isHidden = true
                listContainerView.isHidden = true
                searchSuggestionView.isHidden = false
                listAndSearchOverlayContainerView.isHidden = false
                navigationBar.isInteractiveHidingEnabled = true
                searchSuggestionView.contentInsetAdjustmentBehavior = .never
                scrollView = searchSuggestionView
                searchSuggestionController.navigationBarHider = navigationBarHider
            case .map:
                fallthrough
            default:
                mapView.isHidden = false
                listContainerView.isHidden = true
                searchSuggestionView.isHidden = true
                listAndSearchOverlayContainerView.isHidden = true
                navigationBar.isInteractiveHidingEnabled = false
            }
            recenterOnUserLocationButton.isHidden = mapView.isHidden
            if (mapView.isHidden) {
                redoSearchButton.isHidden = true
            } else {
                updateViewIfMapMovedSignificantly(forVisibleRegion: mapView.region)
            }
            listAndSearchOverlayContainerView.radius = isViewModeOverlay ? 5 : 0
        }
    }

    var viewMode: ViewMode = .none {
        didSet {
            guard oldValue != viewMode, viewMode != .none else {
                return
            }
            switch viewMode {
            case .list:
                traitBasedViewMode = useOverlay ? .listOverlay : .list
            case .search:
                traitBasedViewMode = useOverlay ? .searchOverlay : .search
            case .map:
                fallthrough
            default:
                traitBasedViewMode = useOverlay ? .listOverlay : .map
            }
        }
    }

    struct OldString {
        static let noSavedPlaces = WMFLocalizedString("places-filter-no-saved-places", value:"You have no saved places", comment:"Explains that you don't have any saved places")
        static let savedArticlesFilterLocalizedTitle = WMFLocalizedString("places-filter-saved-articles", value:"Saved articles", comment:"Title of places search filter that searches saved articles")
    }
    
    var currentSearchFilter: PlaceFilterType = .top { // TODO: remember last setting?
        didSet {
            guard oldValue != currentSearchFilter else {
                return
            }

            switch viewMode {
            case .search:
                updateSearchCompletionsFromSearchBarText()
            default:
                if let currentSearch = self.currentSearch {
                    self.currentSearch = PlaceSearch(filter: currentSearchFilter, type: currentSearch.type, origin: .system, sortStyle: currentSearch.sortStyle, string: currentSearch.string, region: nil, localizedDescription: currentSearch.localizedDescription, searchResult: currentSearch.searchResult, siteURL: currentSearch.siteURL)
                }
            }
        }
    }
    

    @objc func updateViewModeFromSegmentedControl() {
        switch mapListToggle.selectedSegmentIndex {
        case 0:
            viewMode = .map
        default:
            viewMode = .list
        }
    }
    
    @objc func updateViewModeToMap() {
        guard viewIfLoaded != nil else {
            return
        }
        viewMode = .map
    }
    
    func selectArticlePlace(_ articlePlace: ArticlePlace) {
        mapView.selectAnnotation(articlePlace, animated: articlePlace.identifier != previouslySelectedArticlePlaceIdentifier)
        previouslySelectedArticlePlaceIdentifier = articlePlace.identifier
    }

    // MARK: - Search History
    
    fileprivate func searchHistoryGroup(forFilter: PlaceFilterType) -> String {
        let searchHistoryGroup = "PlaceSearch"
        return "\(searchHistoryGroup).\(forFilter.stringValue)"
    }
    
    fileprivate func currentSearchHistoryGroup() -> String {
        return searchHistoryGroup(forFilter: currentSearchFilter)
    }
    
    func saveToHistory(search: PlaceSearch) {
        guard search.origin == .user else {
            DDLogDebug("not saving system search to history")
            return
        }
        
        do {
            let moc = dataStore.viewContext
            if let keyValue = keyValue(forPlaceSearch: search, inManagedObjectContext: moc) {
                keyValue.date = Date()
            } else if let entity = NSEntityDescription.entity(forEntityName: "WMFKeyValue", in: moc) {
                let keyValue =  WMFKeyValue(entity: entity, insertInto: moc)
                keyValue.key = search.key
                keyValue.group = currentSearchHistoryGroup()
                keyValue.date = Date()
                keyValue.value = search.dictionaryValue as NSCoding
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
            request.predicate = NSPredicate(format: "group == %@", currentSearchHistoryGroup())
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WMFKeyValue.date, ascending: false)]
            let results = try moc.fetch(request)
            for result in results {
                moc.delete(result)
            }
            try moc.save()
        } catch let error {
            DDLogError("Error clearing recent place searches: \(error)")
        }
    }
    
    func keyValue(forPlaceSearch placeSearch: PlaceSearch, inManagedObjectContext moc: NSManagedObjectContext) -> WMFKeyValue? {
        var keyValue: WMFKeyValue?
        do {
            let key = placeSearch.key
            let request = WMFKeyValue.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@ && group == %@", key, currentSearchHistoryGroup())
            request.fetchLimit = 1
            let results = try moc.fetch(request)
            keyValue = results.first
        } catch let error {
            DDLogError("Error fetching place search key value: \(error.localizedDescription)")
        }
        return keyValue
    }
    
    // MARK: - Location Access
    
    func promptForLocationAccess() {
        var skipSearchInDismissEnableLocationPanelHandler = false
        
        let enableLocationButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _ in
            skipSearchInDismissEnableLocationPanelHandler = true // Needed because the call to 'sender.dismiss' below triggers the 'dismissHandler', but we only want to perform the default search if the primary button was not tapped.
            self.presentedViewController?.dismiss(animated: true, completion: {
                guard self.locationManager.authorizationStatus == .notDetermined else {
                    UIApplication.shared.wmf_openAppSpecificSystemSettings()
                    return
                }
                self.locationManager.startMonitoringLocation()
            })
        }
        
        let dismissEnableLocationPanelHandler: ScrollableEducationPanelDismissHandler = {
            if (!skipSearchInDismissEnableLocationPanelHandler) {
                self.performDefaultSearchIfNecessary(withRegion: nil)
            }
        }
        
        let enableLocationPanelVC = EnableLocationPanelViewController(showCloseButton: true, primaryButtonTapHandler: enableLocationButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: dismissEnableLocationPanelHandler, theme: theme)
        
        present(enableLocationPanelVC, animated: true, completion: nil)
    }

    
    // MARK: - Place Grouping
    
    fileprivate var groupingTaskGroup: WMFTaskGroup?
    fileprivate var needsRegroup = false
    fileprivate var showingAllImages = false
    fileprivate var greaterThanOneArticleGroupCount = 0
    
    struct ArticleGroup {
        var articles: [WMFArticle] = []
        var latitudeSum: QuadKeyDegrees = 0
        var longitudeSum: QuadKeyDegrees = 0
        var latitudeAdjustment: QuadKeyDegrees = 0
        var longitudeAdjustment: QuadKeyDegrees = 0
        var baseQuadKey: QuadKey = 0
        var baseQuadKeyPrecision: QuadKeyPrecision = 0
        var location: CLLocation {
            get {
                return CLLocation(latitude: (latitudeSum + latitudeAdjustment)/CLLocationDegrees(articles.count), longitude: (longitudeSum + longitudeAdjustment)/CLLocationDegrees(articles.count))
            }
        }
        
        init () {
            
        }
        
        init(article: WMFArticle) {
            articles = [article]
            latitudeSum = article.coordinate?.latitude ?? 0
            longitudeSum = article.coordinate?.longitude ?? 0
            baseQuadKey = article.quadKey ?? 0
            baseQuadKeyPrecision = QuadKeyPrecision.maxPrecision
        }
    }

    
    func merge(group: ArticleGroup, key: String, groups: [String: ArticleGroup], groupingDistance: CLLocationDistance) -> Set<String> {
        var toMerge = Set<String>()
        if let keyToSelect = articleKeyToSelect, group.articles.first?.key == keyToSelect {
            //no grouping with the article to select
            return toMerge
        }
        
        let baseQuadKey = group.baseQuadKey
        let baseQuadKeyPrecision = group.baseQuadKeyPrecision
        let baseQuadKeyCoordinate = QuadKeyCoordinate(quadKey: baseQuadKey, precision: baseQuadKeyPrecision)
        
        if baseQuadKeyCoordinate.latitudePart > 2 && baseQuadKeyCoordinate.longitudePart > 1 {
            for t: Int64 in -1...1 {
                for n: Int64 in -1...1 {
                    guard t != 0 || n != 0 else {
                        continue
                    }
                    let latitudePart = QuadKeyPart(Int64(baseQuadKeyCoordinate.latitudePart) + 2*t)
                    let longitudePart = QuadKeyPart(Int64(baseQuadKeyCoordinate.longitudePart) + n)
                    let adjacentBaseQuadKey = QuadKey(latitudePart: latitudePart, longitudePart: longitudePart, precision: baseQuadKeyPrecision)
                    let adjacentKey = "\(adjacentBaseQuadKey)|\(adjacentBaseQuadKey + 1)"
                    guard let adjacentGroup = groups[adjacentKey] else {
                        continue
                    }
                    if let keyToSelect = articleKeyToSelect, adjacentGroup.articles.first?.key == keyToSelect {
                        //no grouping with the article to select
                        continue
                    }
                    guard group.articles.count > 1 || adjacentGroup.articles.count > 1 else {
                        continue
                    }
                    let location = group.location
                    let distance = adjacentGroup.location.distance(from: location)
                    let distanceToCheck = group.articles.count == 1 || adjacentGroup.articles.count == 1 ? 0.25*groupingDistance : groupingDistance
                    if distance < distanceToCheck {
                        toMerge.insert(adjacentKey)
                        var newGroups = groups
                        newGroups.removeValue(forKey: key)
                        let others = merge(group: adjacentGroup, key: adjacentKey, groups: newGroups, groupingDistance: groupingDistance)
                        toMerge.formUnion(others)
                    }
                }
            }
        }
        return toMerge
    }
    
    func regroupArticlesIfNecessary(forVisibleRegion visibleRegion: MKCoordinateRegion) {
        guard groupingTaskGroup == nil else {
            needsRegroup = true
            return
        }
        assert(Thread.isMainThread)
        
        guard let searchRegion = currentSearchRegion else {
            return
        }
        
        let deltaLon = visibleRegion.span.longitudeDelta
        let lowestPrecision = QuadKeyPrecision(deltaLongitude: deltaLon)
        let searchDeltaLon = searchRegion.span.longitudeDelta
        let lowestSearchPrecision = QuadKeyPrecision(deltaLongitude: searchDeltaLon)
        var groupingAggressiveness: CLLocationDistance = 0.67
        let groupingPrecisionDelta: QuadKeyPrecision = isViewModeOverlay ? 5 : 4
        let maxPrecision: QuadKeyPrecision = isViewModeOverlay ? 18 : 17
        let minGroupCount = 3
        if lowestPrecision + groupingPrecisionDelta <= lowestSearchPrecision {
            groupingAggressiveness += 0.3
        }
        let currentPrecision = lowestPrecision + groupingPrecisionDelta
        let groupingPrecision = min(maxPrecision, currentPrecision)

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
        
        var annotationsToRemove: [Int:ArticlePlace] = [:]
        
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
        
        var groups: [String: ArticleGroup] = [:]
        var splittableGroups: [String: ArticleGroup] = [:]
        for article in articleFetchedResultsController?.fetchedObjects ?? [] {
            guard let quadKey = article.quadKey else {
                continue
            }
            var group: ArticleGroup
            let adjustedQuadKey: QuadKey
            var key: String
            if groupingPrecision < maxPrecision && (articleKeyToSelect == nil || article.key != articleKeyToSelect) {
                adjustedQuadKey = quadKey.adjusted(downBy: QuadKeyPrecision.maxPrecision - groupingPrecision)
                let baseQuadKey = adjustedQuadKey - adjustedQuadKey % 2
                key = "\(baseQuadKey)|\(baseQuadKey + 1)" // combine neighboring vertical keys
                group = groups[key] ?? ArticleGroup()
                group.baseQuadKey = baseQuadKey
                group.baseQuadKeyPrecision = groupingPrecision
            } else {
                group = ArticleGroup()
                adjustedQuadKey = quadKey
                key = "\(adjustedQuadKey)"
                if var existingGroup = groups[key] {
                    let existingGroupArticleKey = existingGroup.articles.first?.key ?? ""
                    let existingGroupTitle = existingGroup.articles.first?.displayTitle ?? ""
                    existingGroup.latitudeAdjustment = 0.0001 * CLLocationDegrees(existingGroupArticleKey.hash) / CLLocationDegrees(Int.max)
                    existingGroup.longitudeAdjustment = 0.0001 * CLLocationDegrees(existingGroupTitle.hash) / CLLocationDegrees(Int.max)
                    groups[key] = existingGroup
                    
                    let articleKey = article.key ?? ""
                    let articleTitle = article.displayTitle ?? ""
                    group.latitudeAdjustment = 0.0001 * CLLocationDegrees(articleKey.hash) / CLLocationDegrees(Int.max)
                    group.longitudeAdjustment = 0.0001 * CLLocationDegrees(articleTitle.hash) / CLLocationDegrees(Int.max)
                    key = articleKey
                }
                group.baseQuadKey = quadKey
                group.baseQuadKeyPrecision = QuadKeyPrecision.maxPrecision
            }
            group.articles.append(article)
            let coordinate = QuadKeyCoordinate(quadKey: quadKey)
            group.latitudeSum += coordinate.latitude
            group.longitudeSum += coordinate.longitude
            groups[key] = group
            if group.articles.count > 1 {
                if group.articles.count < minGroupCount {
                    splittableGroups[key] = group
                } else {
                    splittableGroups[key] = nil
                }
            }
        }
        
        
        for (key, group) in splittableGroups {
            for (index, article) in group.articles.enumerated() {
                groups[key + ":\(index)"] = ArticleGroup(article: article)
            }
            groups.removeValue(forKey: key)
        }
        
        greaterThanOneArticleGroupCount = 0
        let keys = groups.keys
        for key in keys {
            guard var group = groups[key] else {
                continue
            }
            
            if groupingPrecision < maxPrecision {
                let toMerge = merge(group: group, key: key, groups: groups, groupingDistance: groupingDistance)
                for adjacentKey in toMerge {
                    guard let adjacentGroup = groups[adjacentKey] else {
                        continue
                    }
                    group.articles.append(contentsOf: adjacentGroup.articles)
                    group.latitudeSum += adjacentGroup.latitudeSum
                    group.longitudeSum += adjacentGroup.longitudeSum
                    groups.removeValue(forKey: adjacentKey)
                }
                
                
                if group.articles.count > 1 {
                    greaterThanOneArticleGroupCount += 1
                }
            }
            
            var nextCoordinate: CLLocationCoordinate2D?
            var coordinate = group.location.coordinate
            
            let identifier = ArticlePlace.identifierForArticles(articles: group.articles)
            
            //check for identical place already on the map
            if let _ = annotationsToRemove.removeValue(forKey: identifier) {
                continue
            }
            
            if group.articles.count == 1 {
                if let article = group.articles.first, let key = article.key, let previousPlace = previousPlaceByArticle[key] {
                    nextCoordinate = coordinate
                    coordinate = previousPlace.coordinate
                    if let thumbnailURL = article.thumbnailURL {
                        imageController.prefetch(withURL: thumbnailURL)
                    }
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
                    self.countOfAnimatingAnnotations += 1
                    UIView.animate(withDuration:animationDuration, delay: 0, options: [.allowUserInteraction], animations: {
                        placeView?.alpha = 0
                        if (previousPlace.articles.count > 1) {
                            placeView?.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
                        }
                        previousPlace.coordinate = coordinate
                    }, completion: { (finished) in
                        taskGroup.leave()
                        self.mapView.removeAnnotation(previousPlace)
                        self.countOfAnimatingAnnotations -= 1
                    })
                }
            }

            
            guard let place = ArticlePlace(coordinate: coordinate, nextCoordinate: nextCoordinate, articles: group.articles, identifier: identifier) else {
                continue
            }
            
            mapView.addAnnotation(place)
            
            groups.removeValue(forKey: key)
        }
        
        for (_, annotation) in annotationsToRemove {
            let placeView = mapView.view(for: annotation)
            taskGroup.enter()
            self.countOfAnimatingAnnotations += 1
            UIView.animate(withDuration: 0.5*animationDuration, animations: {
                placeView?.transform = CGAffineTransform(scaleX: self.animationScale, y: self.animationScale)
                placeView?.alpha = 0
            }, completion: { (finished) in
                taskGroup.leave()
                self.mapView.removeAnnotation(annotation)
                self.countOfAnimatingAnnotations -= 1
            })
        }
        currentGroupingPrecision = groupingPrecision
        if greaterThanOneArticleGroupCount > 0 {
            set(shouldShowAllImages: false)
        }
        taskGroup.waitInBackground {
            self.groupingTaskGroup = nil
            self.selectVisibleKeyToSelectIfNecessary()
            if (self.needsRegroup) {
                self.needsRegroup = false
                self.regroupArticlesIfNecessary(forVisibleRegion: self.mapRegion ?? self.mapView.region)
            }
        }
    }
    
    // MARK: - Article Popover
    
    func showPopover(forAnnotationView annotationView: MapAnnotationView) {
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

        if isViewModeOverlay, let indexPath = articleFetchedResultsController?.indexPath(forObject: article) {
            listViewController.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        
        let articleVC = ArticlePopoverViewController(article)
        articleVC.delegate = self
        articleVC.view.alpha = 0
        articleVC.apply(theme: theme)
        articleVC.configureView(withTraitCollection: traitCollection)
        
        let articleLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if locationManager.isUpdating, let userLocation = locationManager.location {
            let distance = articleLocation.distance(from: userLocation)
            let distanceString = MKDistanceFormatter().string(fromDistance: distance)
            articleVC.descriptionLabel.text = distanceString
        } else {
            articleVC.descriptionLabel.text = nil
        }
       
        addChild(articleVC)
        view.insertSubview(articleVC.view, belowSubview: navigationBar)
        articleVC.didMove(toParent: self)
        
        let size = articleVC.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        articleVC.preferredContentSize = size
        selectedArticlePopover = articleVC
        selectedArticleAnnotationView = annotationView
        selectedArticleKey = articleKey
        
        adjustLayout(ofPopover: articleVC, withSize:size, viewSize:view.bounds.size, forAnnotationView: annotationView)
        
        articleVC.update()
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: articleVC.view)
        
        articleVC.view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        articleVC.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: popoverFadeDuration) {
            articleVC.view.transform = CGAffineTransform.identity
            articleVC.view.alpha = 1
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            if let popover = self.selectedArticlePopover,
                let annotationView = self.selectedArticleAnnotationView {
                self.adjustLayout(ofPopover: popover, withSize: popover.preferredContentSize, viewSize: size, forAnnotationView: annotationView)
            }
            self.updateTraitBasedViewMode()
        }, completion: nil)
    }
    
    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        emptySearchOverlayView.frame = searchSuggestionView.frame.inset(by: searchSuggestionView.contentInset)
    }

    // MARK: HintPresenting

    var hintController: HintController?
    
    func dismissCurrentArticlePopover() {
        guard let popover = selectedArticlePopover else {
            return
        }
        UIView.animate(withDuration: popoverFadeDuration, animations: {
            popover.view.alpha = 0
            popover.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { (done) in
            popover.willMove(toParent: nil)
            popover.view.removeFromSuperview()
            popover.removeFromParent()
        }
        selectedArticlePopover = nil
        selectedArticleAnnotationView = nil
    }
    
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction action: WMFArticleAction) {
        perform(action: action, onArticle: articlePopoverViewController.article)
    }
    
    func perform(action: WMFArticleAction, onArticle article: WMFArticle) {
        guard let url = article.url else {
            return
        }
        switch action {
        case .read:
            navigate(to: url)
            break
        case .save:
            let didSave = dataStore.savedPageList.toggleSavedPage(for: url)
            if didSave {
                ReadingListsFunnel.shared.logSaveInPlaces(url)
            } else {
                ReadingListsFunnel.shared.logUnsaveInPlaces(url)
            }
            break
        case .share:
            let addToReadingListActivity = AddToReadingListActivity {
                let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: self.dataStore, articles: [article], theme: self.theme)
                let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: self.theme)
                navigationController.isNavigationBarHidden = true
                addArticlesToReadingListViewController.eventLogAction = { ReadingListsFunnel.shared.logSaveInPlaces(url) }
                self.present(navigationController, animated: true, completion: nil)
            }
            let shareActivityController = ShareActivityController(article: article, customActivities: [addToReadingListActivity])
            shareActivityController.popoverPresentationController?.sourceView = view
            var sourceRect = view.bounds
            if let shareButton = selectedArticlePopover?.shareButton {
                sourceRect = view.convert(shareButton.frame, from: shareButton.superview)
            }
            shareActivityController.popoverPresentationController?.sourceRect = sourceRect
            shareActivityController.excludedActivityTypes = [.addToReadingList]
            present(shareActivityController, animated: true, completion: nil)
            break
        case .none:
            fallthrough
        default:
            break
        }
    }
    
    enum PopoverLocation {
        case top
        case bottom
        case left
        case right
    }
    
    func adjustLayout(ofPopover articleVC: ArticlePopoverViewController, withSize popoverSize: CGSize, viewSize: CGSize, forAnnotationView annotationView: MapAnnotationView) {
        var preferredLocations = [PopoverLocation]()
        
        
        let annotationSize = annotationView.frame.size
        let spacing: CGFloat = 5
        let annotationCenter = view.convert(annotationView.center, from: mapView)
        
        if isViewModeOverlay {
            if UIApplication.shared.wmf_isRTL {
                if annotationCenter.x >= listAndSearchOverlayContainerView.frame.minX {
                    preferredLocations = [.bottom, .left, .right, .top]
                } else {
                    preferredLocations = [.left, .bottom, .top, .right]
                }
            } else {
                if annotationCenter.x <= listAndSearchOverlayContainerView.frame.maxX {
                    preferredLocations = [.bottom, .right, .left, .top]
                } else {
                    preferredLocations = [.right, .bottom, .top, .left]
                }
            }
        }
    
        let viewCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        let popoverDistanceFromAnnotationCenterY = 0.5 * annotationSize.height + spacing
        let totalHeight = popoverDistanceFromAnnotationCenterY + popoverSize.height + spacing
        let top = totalHeight - annotationCenter.y
        let bottom = annotationCenter.y + totalHeight - viewSize.height
        
        let popoverDistanceFromAnnotationCenterX = 0.5 * annotationSize.width + spacing
        let totalWidth = popoverDistanceFromAnnotationCenterX + popoverSize.width + spacing
        let left = totalWidth - annotationCenter.x
        let right = annotationCenter.x + totalWidth - viewSize.width

        let navBarHeight = navigationBar.visibleHeight
        var x = annotationCenter.x > viewCenter.x ? viewSize.width - popoverSize.width - spacing : spacing
        var y = annotationCenter.y > viewCenter.y ? viewSize.height - popoverSize.height - spacing : spacing + navBarHeight

        let canFitTopOrBottom = viewSize.width - annotationCenter.x > 0.5*popoverSize.width && annotationCenter.x > 0.5*popoverSize.width
        let fitsTop = top < -navBarHeight && canFitTopOrBottom
        let fitsBottom = bottom < 0 && canFitTopOrBottom
        
        let canFitLeftOrRight = viewSize.height - annotationCenter.y > 0.5*popoverSize.height && annotationCenter.y - navBarHeight > 0.5*popoverSize.height
        let fitsLeft = left < 0 && canFitLeftOrRight
        let fitsRight = right < 0 && canFitLeftOrRight
        
        var didFitPreferredLocation = false
        for preferredLocation in preferredLocations {
            didFitPreferredLocation = true
            if preferredLocation == .top && fitsTop {
                x = annotationCenter.x - 0.5 * popoverSize.width
                y = annotationCenter.y - popoverDistanceFromAnnotationCenterY - popoverSize.height
            } else if preferredLocation == .bottom && fitsBottom {
                x = annotationCenter.x - 0.5 * popoverSize.width
                y = annotationCenter.y + popoverDistanceFromAnnotationCenterY
            } else if preferredLocation == .left && fitsLeft {
                x = annotationCenter.x - popoverDistanceFromAnnotationCenterX - popoverSize.width
                y = annotationCenter.y - 0.5 * popoverSize.height
            } else if preferredLocation == .right && fitsRight {
                x = annotationCenter.x + popoverDistanceFromAnnotationCenterX
                y = annotationCenter.y - 0.5 * popoverSize.height
            } else if preferredLocation == .top && top < -navBarHeight {
                y = annotationCenter.y - popoverDistanceFromAnnotationCenterY - popoverSize.height
            } else if preferredLocation == .bottom && bottom < 0 {
                y = annotationCenter.y + popoverDistanceFromAnnotationCenterY
            } else if preferredLocation == .left && left < 0 {
                x = annotationCenter.x - popoverDistanceFromAnnotationCenterX - popoverSize.width
            } else if preferredLocation == .right && right < 0 {
                x = annotationCenter.x + popoverDistanceFromAnnotationCenterX
            } else {
                didFitPreferredLocation = false
            }
            
            if didFitPreferredLocation {
                break
            }
        }
        
        if (!didFitPreferredLocation) {
            if (fitsTop || fitsBottom) {
                x = annotationCenter.x - 0.5 * popoverSize.width
                y = annotationCenter.y + (top < bottom ? 0 - popoverDistanceFromAnnotationCenterY - popoverSize.height : popoverDistanceFromAnnotationCenterY)
            } else if (fitsLeft || fitsRight) {
                x = annotationCenter.x + (left < right ? 0 - popoverDistanceFromAnnotationCenterX - popoverSize.width : popoverDistanceFromAnnotationCenterX)
                y = annotationCenter.y - 0.5 * popoverSize.height
            } else if (top < -navBarHeight) {
                y = annotationCenter.y - popoverDistanceFromAnnotationCenterY - popoverSize.height
            } else if (bottom < 0) {
                y = annotationCenter.y + popoverDistanceFromAnnotationCenterY
            } else if (left < 0) {
                x = annotationCenter.x - popoverDistanceFromAnnotationCenterX - popoverSize.width
            } else if (right < 0) {
                x = annotationCenter.x + popoverDistanceFromAnnotationCenterX
            }
        }
       
        articleVC.view.frame = CGRect(origin: CGPoint(x: x, y: y), size: popoverSize)
    }
    
    // MARK: - Search Filter Dropdown
    
    fileprivate func showSearchFilterDropdown(completion: @escaping ((Bool) -> Void)) {

    }
    
    fileprivate func hideSearchFilterDropdown(completion: @escaping ((Bool) -> Void)) {

    }

    fileprivate func updateSearchBarText(forSearch search: PlaceSearch) {
        if (isDefaultSearch(search)) {
            searchBar.text = nil
        } else {
            searchBar.text = search.string ?? search.localizedDescription
        }
        
    }
    
    fileprivate func updateSearchBarText() {
        guard let search = currentSearch else {
            searchBar.text = nil
            return
        }
        updateSearchBarText(forSearch: search)
    }
    
    func setupEmptySearchOverlayView() {
        emptySearchOverlayView.mainLabel.text = WMFLocalizedString("places-empty-search-title", value:"Search for Wikipedia articles with geographic locations", comment:"Title text shown on an overlay when there are no recent Places searches. Describes that you can search Wikipedia for articles with geographic locations.")
        emptySearchOverlayView.detailLabel.text = WMFLocalizedString("places-empty-search-description", value:"Explore cities, countries, continents, natural landmarks, historical events, buildings and more.", comment:"Detail text shown on an overlay when there are no recent Places searches. Describes the kind of articles you can search for.")
    }
    
    // MARK: - Search Suggestions & Completions
    
    var currentSearchString: String {
        guard let currentSearchString = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) else {
            return ""
        }
        return currentSearchString
    }
    
    func updateSearchSuggestions(withCompletions completions: [PlaceSearch], isSearchDone: Bool) {
        guard currentSearchString != "" || !completions.isEmpty else {
            
            // Search is empty, run a default search
            
            var defaultSuggestions = [PlaceSearch]()
            
            let yourLocationSuggestionTitle = WMFLocalizedString("places-search-your-current-location", value:"Your current location", comment:"A search suggestion for showing articles near your current location.")
            defaultSuggestions.append(PlaceSearch(filter: currentSearchFilter, type: .nearby, origin: .user, sortStyle: .links, string: nil, region: nil, localizedDescription: yourLocationSuggestionTitle, searchResult: nil))
            
            switch (currentSearchFilter) {
            case .top:
                defaultSuggestions.append(PlaceSearch(filter: .top, type: .location, origin: .system, sortStyle: .links, string: nil, region: nil, localizedDescription: WMFLocalizedString("places-search-top-articles", value:"All top articles", comment:"A search suggestion for top articles"), searchResult: nil))
            case .saved:
                defaultSuggestions.append(PlaceSearch(filter: .saved, type: .location, origin: .system, sortStyle: .links, string: nil, region: nil, localizedDescription: WMFLocalizedString("places-search-saved-articles", value:"All saved articles", comment:"A search suggestion for saved articles"), searchResult: nil))
            }

            var recentSearches: [PlaceSearch] = []
            do {
                let moc = dataStore.viewContext
                let request = WMFKeyValue.fetchRequest()
                request.predicate = NSPredicate(format: "group == %@", currentSearchHistoryGroup())
                request.sortDescriptors = [NSSortDescriptor(keyPath: \WMFKeyValue.date, ascending: false)]
                let results = try moc.fetch(request)
                let count = results.count
                if count > searchHistoryCountLimit {
                    for result in results[searchHistoryCountLimit..<count] {
                        moc.delete(result)
                    }
                }
                let limit = min(count, searchHistoryCountLimit)
                recentSearches = try results[0..<limit].map({ (kv) -> PlaceSearch in
                    guard let ps = PlaceSearch(object: kv.value) else {
                            throw PlaceSearchError.deserialization(object: kv.value)
                    }
                    return ps
                })
            } catch let error {
                DDLogError("Error fetching recent place searches: \(error)")
            }
            searchSuggestionController.siteURL = siteURL
            searchSuggestionController.searches = [defaultSuggestions, recentSearches, [], []]
            
            let searchText = searchBar.text ?? ""
            if !searchText.wmf_hasNonWhitespaceText && recentSearches.isEmpty {
                setupEmptySearchOverlayView()
                emptySearchOverlayView.frame = searchSuggestionView.frame.inset(by: searchSuggestionView.contentInset)
                searchSuggestionView.superview?.addSubview(emptySearchOverlayView)
            } else {
                emptySearchOverlayView.removeFromSuperview()
            }

            return
        }
        
        emptySearchOverlayView.removeFromSuperview()
        
        guard currentSearchString != "" else {
            searchSuggestionController.searches = [[], [], [], completions]
            return
        }

        let currentSearchScopeName: String
        switch (currentSearchFilter) {
        case .top:
            currentSearchScopeName = WMFLocalizedString("places-search-top-articles-that-match-scope", value: "Nearby", comment: "Title used in search description when searching an area for Top articles")
        case .saved:
            currentSearchScopeName = OldString.savedArticlesFilterLocalizedTitle
        }

        var currentSearchStringSuggestions = [PlaceSearch]()
        if isSearchDone {
            let currentSearchStringTitle = String.localizedStringWithFormat(WMFLocalizedString("places-search-articles-that-match", value:"%1$@ matching “%2$@”", comment:"A search suggestion for filtering the articles in the area by the search string. %1$@ is replaced by the a string depending on the current filter ('Nearby' for 'Top Articles' or 'Saved articles'). %2$@ is replaced with the search string"), currentSearchScopeName, currentSearchString)
            currentSearchStringSuggestions.append(PlaceSearch(filter: currentSearchFilter, type: .text, origin: .user, sortStyle: .links, string: currentSearchString, region: nil, localizedDescription: currentSearchStringTitle, searchResult: nil))
        }
        
        searchSuggestionController.searches = [[], [], currentSearchStringSuggestions, completions]
    }
    
    func handleCompletion(searchResults: [MWKSearchResult], siteURL: URL) -> [PlaceSearch] {
        var set = Set<String>()
        let completions = searchResults.compactMap { (result) -> PlaceSearch? in
            guard let location = result.location,
                let dimension = result.geoDimension?.doubleValue,
                let url = result.articleURL(forSiteURL: siteURL),
                let key = url.wmf_databaseKey,
                !set.contains(key) else {
                    return nil
            }
            set.insert(key)
            let region = [location.coordinate].wmf_boundingRegion(with: dimension)
            return PlaceSearch(filter: currentSearchFilter, type: .location, origin: .user, sortStyle: .links, string: nil, region: region, localizedDescription: result.displayTitle, searchResult: result, siteURL: siteURL)
        }
        updateSearchSuggestions(withCompletions: completions, isSearchDone: true)
        return completions
    }
    
    @objc public func showNearbyArticles() {
        guard let _ = view else { // force view instantiation
            return
        }
        
        guard currentSearch != nil else { // if current search is nil, this is the initial setup for the view and it will recenter automatically
            return
        }
        
        currentSearch = nil // will cause the default search to perform after re-centering
        recenterOnUserLocation(self)
    }
    
    @objc public func showArticleURL(_ articleURL: URL) {
        guard let article = dataStore.fetchArticle(with: articleURL), let title = articleURL.wmf_title,
            let _ = view else { // force view instantiation
            return
        }
        let region = self.region(thatFits: [article])
        let displayTitleHTML = article.displayTitleHTML
        let displayTitle = article.displayTitle ?? title
        let searchResult = MWKSearchResult(articleID: 0, revID: 0, title: title, displayTitle: displayTitle, displayTitleHTML: displayTitleHTML, wikidataDescription: article.wikidataDescription, extract: article.snippet, thumbnailURL: article.thumbnailURL, index: nil, titleNamespace: nil, location: article.location)
        currentSearch = PlaceSearch(filter: .top, type: .location, origin: .user, sortStyle: .links, string: nil, region: region, localizedDescription: title, searchResult: searchResult, siteURL: articleURL.wmf_site)
    }
    
    fileprivate func searchForFirstSearchSuggestion() {
        if !searchSuggestionController.searches[PlaceSearchSuggestionController.completionSection].isEmpty {
            currentSearch = searchSuggestionController.searches[PlaceSearchSuggestionController.completionSection][0]
        } else if !searchSuggestionController.searches[PlaceSearchSuggestionController.currentStringSection].isEmpty {
            currentSearch = searchSuggestionController.searches[PlaceSearchSuggestionController.currentStringSection][0]
        }
    }
    
    fileprivate var isWaitingForSearchSuggestionUpdate = false {
        didSet {
            if (oldValue == false && isWaitingForSearchSuggestionUpdate == true) {
                // start progress bar
                fakeProgressController.start()
            } else if (isWaitingForSearchSuggestionUpdate == false) {
                // stop progress bar
                fakeProgressController.finish()
            }
        }
    }
    
    @objc func updateSearchCompletionsFromSearchBarText() {
        switch currentSearchFilter {
        case .saved:
            updateSearchSuggestions(withCompletions: [], isSearchDone: true)
            self.isWaitingForSearchSuggestionUpdate = false
        default:
            updateSearchCompletionsFromSearchBarTextForTopArticles()
        }
    }
    
    func updateSearchCompletionsFromSearchBarTextForTopArticles()
    {
        guard let text = searchBar.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines), text != "" else {
            updateSearchSuggestions(withCompletions: [], isSearchDone: false)
            self.isWaitingForSearchSuggestionUpdate = false
            return
        }
        let siteURL = self.siteURL
        searchFetcher.fetchArticles(forSearchTerm: text, siteURL: siteURL, resultLimit: 24, failure: { (error) in
            DispatchQueue.main.async {
                guard text == self.searchBar.text else {
                    return
                }
                self.updateSearchSuggestions(withCompletions: [], isSearchDone: false)
                self.isWaitingForSearchSuggestionUpdate = false
            }
        }) { (searchResult) in
            DispatchQueue.main.async {
                guard text == self.searchBar.text else {
                    return
                }
                
                if let suggestion = searchResult.searchSuggestion {
                    DDLogDebug("got suggestion! \(suggestion)")
                }
                
                let completions = self.handleCompletion(searchResults: searchResult.results ?? [], siteURL: siteURL)
                self.isWaitingForSearchSuggestionUpdate = false
                guard completions.count < 10 else {
                    return
                }
                
                let center = self.mapView.userLocation.coordinate
                let region = CLCircularRegion(center: center, radius: 40075000, identifier: "world")
                self.locationSearchFetcher.fetchArticles(withSiteURL: self.siteURL, in: region, matchingSearchTerm: text, sortStyle: .links, resultLimit: 24, completion: { (locationSearchResults) in
                    DispatchQueue.main.async {
                        guard text == self.searchBar.text else {
                            return
                        }
                        var combinedResults: [MWKSearchResult] = searchResult.results ?? []
                        let newResults = locationSearchResults.results as [MWKSearchResult]
                        combinedResults.append(contentsOf: newResults)
                        let _ = self.handleCompletion(searchResults: combinedResults, siteURL: siteURL)
                    }
                }) { (error) in }
            }
        }
    }
    
    private func closeSearch() {
        searchBar.endEditing(true)
        currentSearch = nil
        performDefaultSearchIfNecessary(withRegion: nil)
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: view)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        viewMode = .search
        deselectAllAnnotations()
        
        // Only update suggestion on *begin* editing if there is no text
        // Otherwise, it just clears perfectly good results
        if currentSearchString == "" {
            updateSearchSuggestions(withCompletions: [], isSearchDone: false)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isWaitingForSearchSuggestionUpdate = true
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(updateSearchCompletionsFromSearchBarText), with: nil, afterDelay: 0.2)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        closeSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let searchText = searchBar.text else {
            assertionFailure("could not read search text")
            return
        }
        
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        guard !isWaitingForSearchSuggestionUpdate else {
            return
        }
        
        searchBar.endEditing(true)
        searchForFirstSearchSuggestion()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        updateViewModeFromSegmentedControl()
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let article = article(at: indexPath) else {
            return
        }
        perform(action: .read, onArticle: article)
    }
    
    // MARK: - PlaceSearchSuggestionControllerDelegate
    
    func placeSearchSuggestionController(_ controller: PlaceSearchSuggestionController, didSelectSearch search: PlaceSearch) {
        searchBar.endEditing(true)
        currentSearch = search
    }
    
    func placeSearchSuggestionControllerClearButtonPressed(_ controller: PlaceSearchSuggestionController) {
        clearSearchHistory()
        updateSearchSuggestions(withCompletions: [], isSearchDone: false)
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
        updateSearchSuggestions(withCompletions: [], isSearchDone: false)
    }
    
    // MARK: - WMFLocationManagerDelegate
    
    func updateUserLocationAnnotationViewHeading(_ heading: CLHeading) {
        guard let view = mapView.view(for: mapView.userLocation) as? UserLocationAnnotationView else {
            return
        }
        view.isHeadingArrowVisible = heading.headingAccuracy > 0 && heading.headingAccuracy < 90
        view.heading = heading.trueHeading
    }
    
    func zoomAndPanMapView(toLocation location: CLLocation) {
        let region = [location.coordinate].wmf_boundingRegion(with: 10000)
        mapRegion = region
        if let searchRegion = currentSearchRegion, isDistanceSignificant(betweenRegion: searchRegion, andRegion: region) {
            performDefaultSearch(withRegion: mapRegion)
        } else {
            performDefaultSearchIfNecessary(withRegion: region)
        }
    }
    
    var panMapToNextLocationUpdate = true
    
    @IBAction fileprivate func recenterOnUserLocation(_ sender: Any) {
        guard locationManager.isAuthorized, let userLocation = locationManager.location else {
            promptForLocationAccess()
            return
        }
        zoomAndPanMapView(toLocation: userLocation)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updatePlaces()
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        let oldRect = rect.pointee
        let center = CGPoint(x: view.pointee.bounds.midX, y: view.pointee.bounds.midY)
        let newOrigin = CGPoint(x: center.x - 0.5*oldRect.width, y: center.y - 0.5*oldRect.height)
        rect.pointee = CGRect(origin: newOrigin, size: oldRect.size)
    }
    
    // MARK: - ArticlePlaceViewDelegate
    
    func articlePlaceViewWasTapped(_ articlePlaceView: ArticlePlaceView) {
        guard let article = selectedArticlePopover?.article else {
            return
        }
        perform(action: .read, onArticle: article)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === overlaySliderPanGestureRecognizer else {
            return false
        }
        
        let location = touch.location(in: view)
        let shouldReceive = location.x < listAndSearchOverlayContainerView.frame.maxX && abs(location.y - listAndSearchOverlayContainerView.frame.maxY - 10) < 32
        return shouldReceive
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.baseBackground
        navigationBar.apply(theme: theme)

        searchBar.apply(theme: theme)
        searchBar.backgroundColor = theme.colors.paperBackground

        searchSuggestionController.apply(theme: theme)

        listAndSearchOverlayContainerView.backgroundColor = theme.colors.chromeBackground
        listAndSearchOverlaySliderView.backgroundColor = theme.colors.chromeBackground
        listAndSearchOverlaySliderView.tintColor = theme.colors.tertiaryText

        mapContainerView.backgroundColor = theme.colors.baseBackground

        listAndSearchOverlaySliderSeparator.backgroundColor = theme.colors.midBackground

        emptySearchOverlayView.backgroundColor = theme.colors.midBackground
        emptySearchOverlayView.mainLabel.textColor = theme.colors.primaryText
        emptySearchOverlayView.detailLabel.textColor = theme.colors.secondaryText

        recenterOnUserLocationButton.backgroundColor = theme.colors.chromeBackground
        selectedArticlePopover?.apply(theme: theme)
        redoSearchButton.backgroundColor = theme.colors.link
        didYouMeanButton.backgroundColor = theme.colors.link
        listViewController.apply(theme: theme)
    }
}

extension PlacesViewController {
    func regionWillChange() {
        deselectAllAnnotations()
        isMovingToRegion = true
        hintController?.dismissHintDueToUserInteraction()
    }
    
    func regionDidChange() {
        _mapRegion = mapView.region
        guard performDefaultSearchOnNextMapRegionUpdate == false else {
            performDefaultSearchOnNextMapRegionUpdate = false
            performDefaultSearchIfNecessary(withRegion: nil)
            return
        }
        regroupArticlesIfNecessary(forVisibleRegion: mapView.region)
        
        updateViewIfMapMovedSignificantly(forVisibleRegion: mapView.region)
        
        isMovingToRegion = false
        
        selectVisibleKeyToSelectIfNecessary()
        
        updateShouldShowAllImagesIfNecessary()
    }
    
    func didSelect(place: ArticlePlace, annotationView: MapAnnotationView) {
        previouslySelectedArticlePlaceIdentifier = place.identifier
        
        guard place.articles.count == 1 else {
            deselectAllAnnotations()
            
            var minDistance = CLLocationDistanceMax
            let center = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            for article in place.articles {
                guard let location = article.location else {
                    continue
                }
                let distance = location.distance(from: center)
                if distance < minDistance {
                    minDistance = distance
                    articleKeyToSelect = article.key
                }
            }
            mapRegion = region(thatFits: place.articles)
            return
        }
        
        showPopover(forAnnotationView: annotationView)
    }
    
    func didDeselectAnnotation() {
        selectedArticleKey = nil
        dismissCurrentArticlePopover()
    }
    
    func viewFor(place: ArticlePlace) -> MapAnnotationView? {
        let reuseIdentifier = "org.wikimedia.articlePlaceView"
        var placeView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as! ArticlePlaceView?
        
        if placeView == nil {
            placeView = ArticlePlaceView(annotation: place, reuseIdentifier: reuseIdentifier)
        } else {
            placeView?.prepareForReuse()
            placeView?.annotation = place
        }
        
        placeView?.delegate = self
        
        if showingAllImages {
            placeView?.set(alwaysShowImage: true, animated: false)
        }
        
        if place.articles.count > 1 && place.nextCoordinate == nil {
            placeView?.alpha = 0
            placeView?.transform = CGAffineTransform(scaleX: animationScale, y: animationScale)
            DispatchQueue.main.async {
                self.countOfAnimatingAnnotations += 1
                UIView.animate(withDuration: self.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                    placeView?.transform = CGAffineTransform.identity
                    placeView?.alpha = 1
                }, completion: { (done) in
                    self.countOfAnimatingAnnotations -= 1
                })
            }
        } else if let nextCoordinate = place.nextCoordinate {
            placeView?.alpha = 0
            DispatchQueue.main.async {
                self.countOfAnimatingAnnotations += 1
                UIView.animate(withDuration: 2*self.animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                    place.coordinate = nextCoordinate
                }, completion: { (done) in
                    self.countOfAnimatingAnnotations -= 1
                })
                UIView.animate(withDuration: 0.5*self.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                    placeView?.alpha = 1
                }, completion: nil)
            }
        } else {
            placeView?.alpha = 0
            DispatchQueue.main.async {
                self.countOfAnimatingAnnotations += 1
                UIView.animate(withDuration: self.animationDuration, delay: 0, options: .allowUserInteraction, animations: {
                    placeView?.alpha = 1
                }, completion: { (done) in
                    self.countOfAnimatingAnnotations -= 1
                })
            }
        }
        
        return placeView
    }
}
    
// MARK: - MKMapViewDelegate
extension PlacesViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        regionWillChange()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionDidChange()
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotationView: MKAnnotationView) {
        guard let place = annotationView.annotation as? ArticlePlace, let annotationView = annotationView as? MapAnnotationView else {
            return
        }
        
        didSelect(place: place, annotationView: annotationView)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        didDeselectAnnotation()
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
        
        return viewFor(place: place)
    }
}

// MARK: - LocationManagerDelegate
extension PlacesViewController: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate location: CLLocation) {
        guard panMapToNextLocationUpdate else {
            return
        }
        panMapToNextLocationUpdate = false
        zoomAndPanMapView(toLocation: location)
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate heading: CLHeading) {
        updateUserLocationAnnotationViewHeading(heading)
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdateAuthorized authorized: Bool) {
        if authorized {
            panMapToNextLocationUpdate = currentSearch == nil
            locationManager.startMonitoringLocation()
        } else {
            panMapToNextLocationUpdate = false
            locationManager.stopMonitoringLocation()
            performDefaultSearchIfNecessary(withRegion: nil)
        }
    }
}

// MARK: -

class PlaceSearchEmptySearchOverlayView: UIView {
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
}

// MARK: - UIViewControllerPreviewingDelegate
extension PlacesViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard viewMode == .list else {
            return nil
        }
        return listViewController.previewingContext(previewingContext, viewControllerForLocation: location)
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.wmf_removePeekableChildViewControllers()
        push(viewControllerToCommit, animated: true)        
    }
}

// MARK: - Accessibility

extension PlacesViewController {
    override func accessibilityPerformEscape() -> Bool {
        switch viewMode {
        case .search:
            closeSearch()
            return true
        default:
            if selectedArticlePopover != nil {
                deselectAllAnnotations()
                return true
            } else {
                return false
            }
        }
    }
}
