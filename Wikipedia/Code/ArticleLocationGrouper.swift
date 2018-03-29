import Foundation
import MapKit

protocol ArticleLocationGrouperViewContext: class {
    var countOfAnimatingAnnotations: Int { get set }
    
    func selectVisibleKeyToSelectIfNecessary()
    func set(shouldShowAllImages: Bool)
}

class ArticleLocationGrouper {
    
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
    
    var greaterThanOneArticleGroupCount = 0
    var currentGroupingPrecision: QuadKeyPrecision = 1
    
    fileprivate var groupingTaskGroup: WMFTaskGroup?
    fileprivate var needsRegroup = false
    
    weak var clusteringViewContext: ArticleLocationGrouperViewContext!
    
    init(context: ArticleLocationGrouperViewContext) {
        self.clusteringViewContext = context
    }
    
    func merge(group: ArticleGroup, key: String, groups: [String: ArticleGroup], groupingDistance: CLLocationDistance, articleKeyToSelect: String?) -> Set<String> {
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
                        let others = merge(group: adjacentGroup, key: adjacentKey, groups: newGroups, groupingDistance: groupingDistance, articleKeyToSelect: articleKeyToSelect)
                        toMerge.formUnion(others)
                    }
                }
            }
        }
        return toMerge
    }
    
    func regroupArticlesIfNecessary(forVisibleRegion visibleRegion: MKCoordinateRegion, articleKeyToSelect: String?, currentSearchRegion: MKCoordinateRegion?, isViewModeOverlay: Bool, mapView: MapView, articleFetchedResultsController: NSFetchedResultsController<WMFArticle>, mapRegion: MKCoordinateRegion?) {
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
        for article in articleFetchedResultsController.fetchedObjects ?? [] {
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
                let toMerge = merge(group: group, key: key, groups: groups, groupingDistance: groupingDistance, articleKeyToSelect: articleKeyToSelect)
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
                        ImageController.shared.prefetch(withURL: thumbnailURL)
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
                    clusteringViewContext.countOfAnimatingAnnotations += 1
                    UIView.animate(withDuration:0.6, delay: 0, options: [.allowUserInteraction], animations: {
                        placeView?.alpha = 0
                        if (previousPlace.articles.count > 1) {
                            placeView?.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                        }
                        previousPlace.coordinate = coordinate
                    }, completion: { (finished) in
                        taskGroup.leave()
                        mapView.removeAnnotation(previousPlace)
                        self.clusteringViewContext.countOfAnimatingAnnotations -= 1
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
            clusteringViewContext.countOfAnimatingAnnotations += 1
            UIView.animate(withDuration: 0.3, animations: {
                placeView?.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                placeView?.alpha = 0
            }, completion: { (finished) in
                taskGroup.leave()
                mapView.removeAnnotation(annotation)
                self.clusteringViewContext.countOfAnimatingAnnotations -= 1
            })
        }
        currentGroupingPrecision = groupingPrecision
        if greaterThanOneArticleGroupCount > 0 {
            clusteringViewContext.set(shouldShowAllImages: false)
        }
        taskGroup.waitInBackground {
            self.groupingTaskGroup = nil
            self.clusteringViewContext.selectVisibleKeyToSelectIfNecessary()
            if (self.needsRegroup) {
                self.needsRegroup = false
                self.regroupArticlesIfNecessary(forVisibleRegion: mapRegion ?? mapView.region, articleKeyToSelect: articleKeyToSelect, currentSearchRegion: currentSearchRegion, isViewModeOverlay: isViewModeOverlay, mapView: mapView, articleFetchedResultsController: articleFetchedResultsController, mapRegion: mapRegion)
            }
        }
    }
}
