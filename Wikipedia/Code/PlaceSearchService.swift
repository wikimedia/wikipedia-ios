import Foundation
import MapKit
import WMF
import CocoaLumberjackSwift

struct PlaceSearchResult
{
    let locationResults: [MWKSearchResult]?
    let fetchRequest: NSFetchRequest<WMFArticle>?
    let error: Error?
    
    init(locationResults: [MWKSearchResult]?, fetchRequest: NSFetchRequest<WMFArticle>?) {
        self.locationResults = locationResults
        self.fetchRequest = fetchRequest
        self.error = nil
    }
    
    init(error: Error?) { // TODO: make non-optional?
        self.locationResults = nil
        self.fetchRequest = nil
        self.error = error
    }
}

class PlaceSearchService
{
    public let dataStore: MWKDataStore
    private let locationSearchFetcher = WMFLocationSearchFetcher()
    private let wikidataFetcher: WikidataFetcher
    
    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.wikidataFetcher = WikidataFetcher(session: dataStore.session, configuration: dataStore.configuration)
    }
    
    var fetchRequestForSavedArticlesWithLocation: NSFetchRequest<WMFArticle> {
        get {
            let savedRequest = WMFArticle.fetchRequest()
            savedRequest.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey != NULL")
            return savedRequest
        }
    }
    
    var fetchRequestForSavedArticles: NSFetchRequest<WMFArticle> {
        get {
            let savedRequest = WMFArticle.fetchRequest()
            savedRequest.predicate = NSPredicate(format: "savedDate != NULL")
            return savedRequest
        }
    }

    public func performSearch(_ search: PlaceSearch, defaultSiteURL: URL, region: MKCoordinateRegion, completion: @escaping (PlaceSearchResult) -> Void) {
        var result: PlaceSearchResult?
        let siteURL =  search.siteURL ?? defaultSiteURL
        var searchTerm: String? = nil
        let sortStyle = search.sortStyle

        let done = {
            let completionResult: PlaceSearchResult
            if var actualResult = result {
                if let searchResult = search.searchResult {
                    var foundResult = false
                    var locationResults = actualResult.locationResults ?? []
                    for result in locationResults {
                        if result.articleID == searchResult.articleID {
                            foundResult = true
                            break
                        }
                    }
                    if !foundResult {
                        locationResults.append(searchResult)
                        actualResult = PlaceSearchResult(locationResults: locationResults, fetchRequest: actualResult.fetchRequest)
                    }
                }
                completionResult = actualResult
            } else {
                completionResult = PlaceSearchResult(error: nil)
            }
            DispatchQueue.main.async {
                completion(completionResult)
            }
        }
        
        searchTerm = search.string

        switch search.filter {
        case .saved:
            self.fetchSavedArticles(searchString: search.string, completion: { (request) in
                result = PlaceSearchResult(locationResults: nil, fetchRequest: request)
                done()
            })
            
        case .top:
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
                    result = PlaceSearchResult(locationResults: searchResults.results, fetchRequest: nil)
                    done()
                }) { (error) in
                    result = PlaceSearchResult(error: error)
                    done()
                }
        }
    }

    public func fetchSavedArticles(searchString: String?, completion: @escaping (NSFetchRequest<WMFArticle>?) -> () = {_ in }) {
        let moc = dataStore.viewContext
        let done = {
            let request = WMFArticle.fetchRequest()
            let basePredicate = NSPredicate(format: "savedDate != NULL && signedQuadKey != NULL")
            request.predicate = basePredicate
            if let searchString = searchString {
                let searchPredicate = NSPredicate(format: "(displayTitle CONTAINS[cd] '\(searchString)') OR (snippet CONTAINS[cd] '\(searchString)')")
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, searchPredicate])
            }
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.savedDate, ascending: false)]
            
            completion(request)
        }
        
        do {
            let savedPagesWithLocation = try moc.fetch(fetchRequestForSavedArticlesWithLocation)
            guard savedPagesWithLocation.count >= 99 else {
                let savedPagesWithoutLocationRequest = WMFArticle.fetchRequest()
                savedPagesWithoutLocationRequest.predicate = NSPredicate(format: "savedDate != NULL && signedQuadKey == NULL")
                savedPagesWithoutLocationRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.savedDate, ascending: false)]
                let savedPagesWithoutLocation = try moc.fetch(savedPagesWithoutLocationRequest)
                guard !savedPagesWithoutLocation.isEmpty else {
                    done()
                    return
                }
                let keys = savedPagesWithoutLocation.compactMap({ (article) -> WMFInMemoryURLKey? in
                    return article.inMemoryKey
                })
                // Fetch summaries from the server and update WMFArticle objects
                dataStore.articleSummaryController.updateOrCreateArticleSummariesForArticles(withKeys: keys) { (articles, _) in
                    done()
                }
                return
            }
        } catch let error {
            DDLogError("Error fetching saved articles: \(error.localizedDescription)")
        }
        done()
    }
}
