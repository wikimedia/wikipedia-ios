import Foundation
import MapKit
import WMF

struct PlaceSearchResult
{
    let locationResults: [MWKLocationSearchResult]?
//    lazy var fetchRequest: NSFetchRequest<WMFArticle>? = {
//        return self.getFetchRequest()
//    }()
    
    var fetchRequest: NSFetchRequest<WMFArticle>? {
        return _fetchRequest.value
    }
    
    let error: Error?
    
    //private let getFetchRequest: () -> NSFetchRequest<WMFArticle>?
    private let _fetchRequest: LazyBox<NSFetchRequest<WMFArticle>?>
    
    init(locationResults: [MWKLocationSearchResult]?, getFetchRequest: @escaping () -> NSFetchRequest<WMFArticle>?)
    {
        self.locationResults = locationResults
        //self.getFetchRequest = getFetchRequest
        self._fetchRequest = LazyBox<NSFetchRequest<WMFArticle>?> {
            return getFetchRequest()
        }
        
        
        self.error = nil
    }
    
    init(error: Error?) // TODO: make non-optional?
    {
        self.locationResults = nil
        //self.getFetchRequest = { return nil }
        
        self._fetchRequest = LazyBox<NSFetchRequest<WMFArticle>?> {
            return nil
        }
        
        self.error = error
    }
}


struct TopPlacesSearchResult
{
    let locationResults: [MWKLocationSearchResult]?
    let error: Error?
    
    init(locationResults: [MWKLocationSearchResult]?)
    {
        self.locationResults = locationResults
        self.error = nil
    }
    
    init(error: Error?) // TODO: make non-optional?
    {
        self.locationResults = nil
        self.error = error
    }
}


class PlaceSearchService
{
    public var dataStore: MWKDataStore!
    
    
    private var siteURL: URL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()!
    
    private let locationSearchFetcher = WMFLocationSearchFetcher()
    private let wikidataFetcher = WikidataFetcher()
    
    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }
    
    var fetchRequestForSavedArticlesWithLocation: NSFetchRequest<WMFArticle> {
        get {
            let savedRequest = WMFArticle.fetchRequest()
            savedRequest.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey != NULL")
            return savedRequest
        }
    }
    
//    func performWikidataQuery(forSearch search: PlaceSearch) {
//        let fail = {
//            dispatchOnMainQueue({
////                if let region = search.region {
////                    self.mapRegion = region
////                }
////                self.searching = false
//                var newSearch = search
//                newSearch.needsWikidataQuery = false
//                //self.currentSearch = newSearch
//            })
//        }
//        guard let articleURL = search.searchResult?.articleURL(forSiteURL: siteURL) else {
//            fail()
//            return
//        }
//        
//        wikidataFetcher.wikidataBoundingRegion(forArticleURL: articleURL, failure: { (error) in
//            DDLogError("Error fetching bounding region from Wikidata: \(error)")
//            fail()
//        }, success: { (region) in
//            dispatchOnMainQueue({
////                self.mapRegion = region
////                self.searching = false
//                var newSearch = search
//                newSearch.needsWikidataQuery = false
//                newSearch.region = region
////                self.currentSearch = newSearch
//            })
//        })
//    }

//    func performSearch(_ search: PlaceSearch, region: MKCoordinateRegion, completion: @escaping (PlaceSearchResult) -> Void = {_ in }) {
    
    public func performSearch(_ search: PlaceSearch, region: MKCoordinateRegion, completion: @escaping (PlaceSearchResult) -> Void) {
        var result: PlaceSearchResult?
        let siteURL = self.siteURL
        var searchTerm: String? = nil
        let sortStyle = search.sortStyle

        let done = {
            if (result != nil) {
                completion(result!)
            } else {
                completion(PlaceSearchResult(error: nil))
            }
        }
        
//        switch search.type {
//        case .location:
////            //        guard search.needsWikidataQuery else {
////            //            tracker?.wmf_logActionTapThrough(inContext: searchTrackerContext, contentType: AnalyticsContent(siteURL))
////            //            fallthrough
////            //        }
////            performWikidataQuery(forSearch: search)
////            completion(nil)
//           // return
//            fallthrough
//        case .text:
//            fallthrough
//        default:
//            searchTerm = search.string
//        }
        
        searchTerm = search.string

        switch search.filter {
        case .saved:
            result = PlaceSearchResult(locationResults: nil, getFetchRequest: { () -> NSFetchRequest<WMFArticle>? in
                return self.fetchSavedArticles(searchString: search.string)
            })
            done()
            
        case .top:
            //tracker?.wmf_logAction("Top_article_search", inContext: searchTrackerContext, contentType: AnalyticsContent(siteURL))
            let center = region.center
            let halfLatitudeDelta = region.span.latitudeDelta * 0.5
            let halfLongitudeDelta = region.span.longitudeDelta * 0.5
            let top = CLLocation(latitude: center.latitude + halfLatitudeDelta, longitude: center.longitude)
            let bottom = CLLocation(latitude: center.latitude - halfLatitudeDelta, longitude: center.longitude)
            let left =  CLLocation(latitude: center.latitude, longitude: center.longitude - halfLongitudeDelta)
            let right =  CLLocation(latitude: center.latitude, longitude: center.longitude + halfLongitudeDelta)
            let height = top.distance(from: bottom)
            let width = right.distance(from: left)
            
            let radius = round(0.5*max(width, height))
            let searchRegion = CLCircularRegion(center: center, radius: radius, identifier: "")
            
            locationSearchFetcher.fetchArticles(withSiteURL: siteURL, in: searchRegion, matchingSearchTerm: searchTerm, sortStyle: sortStyle, resultLimit: 50, completion: { (searchResults) in
                    result = PlaceSearchResult(locationResults: searchResults.results, getFetchRequest: {
                        return nil
                    })
                    done()
                }) { (error) in
                    WMFAlertManager.sharedInstance.showWarningAlert(error.localizedDescription, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                    result = PlaceSearchResult(error: error)
                    done()
                }
        }
    }
    
    func fetchSavedArticles(searchString: String?) -> NSFetchRequest<WMFArticle>? {
        let moc = dataStore.viewContext
        let done = { (articlesToShow: [WMFArticle]) -> NSFetchRequest<WMFArticle> in
            let request = WMFArticle.fetchRequest()
            let basePredicate = NSPredicate(format: "savedDate != NULL && signedQuadKey != NULL")
            request.predicate = basePredicate
            if let searchString = searchString {
                let searchPredicate = NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)') OR (snippet CONTAINS[cd] '\(searchString)')")
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
            }
            request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
            
            return request
        }
        
        do {
            let savedPagesWithLocation = try moc.fetch(fetchRequestForSavedArticlesWithLocation)
            guard savedPagesWithLocation.count >= 99 else {
                let savedPagesWithoutLocationRequest = WMFArticle.fetchRequest()
                savedPagesWithoutLocationRequest.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey == NULL")
                savedPagesWithoutLocationRequest.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
                let savedPagesWithoutLocation = try moc.fetch(savedPagesWithoutLocationRequest)
                guard savedPagesWithoutLocation.count > 0 else {
                    return done(savedPagesWithLocation)
                }
                let urls = savedPagesWithoutLocation.flatMap({ (article) -> URL? in
                    return article.url
                })
                var allArticlesWithLocation = savedPagesWithLocation // this should be re-fetched
                dataStore.viewContext.updateOrCreateArticleSummariesForArticles(withURLs: urls) { (articles) in
                    allArticlesWithLocation.append(contentsOf: articles)
                }
                return done(allArticlesWithLocation)
            }
        } catch let error {
            DDLogError("Error fetching saved articles: \(error.localizedDescription)")
        }
        return done([])
    }
}
