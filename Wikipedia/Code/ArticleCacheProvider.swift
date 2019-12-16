
import Foundation

final class ArticleCacheProvider {
    
    func recentCachedURLResponse() {
        //this will be called from SchemeHandler when a web view loads
        //*only* checks URLCache.shared for response.
        //return URLCache.shared.cachedResponse(for: request)
    }
    
    func savedCachedURLResponse() {
        //this will be called from SchemeHandler when a web view load *fails* (test w/ no connection and deleting cache from settings)
        //should try to pull response from DB, this way happy path scheme handler always tries to fetch the latest revision for mobile-html
    }
}
