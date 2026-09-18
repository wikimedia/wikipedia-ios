import Foundation
import CoreLocation
import WMFData
import WMFNativeLocalizations

/// The sort order for a location search.
@objc public enum WMFLocationSearchSortStyle: UInt {
    case none = 0
    case pageViews
    case links
    case pageViewsAndLinks

    var dataControllerSortStyle: WMFArticleSearchDataController.SortStyle {
        switch self {
        case .none: return .none
        case .pageViews: return .pageViews
        case .links: return .links
        case .pageViewsAndLinks: return .pageViewsAndLinks
        }
    }
}

@objc public enum WMFLocationSearchErrorCode: UInt {
    case unknown = 0
    case noResults = 1
}

public let WMFLocationSearchErrorDomain = "org.wikimedia.location.search"

/// Fetches articles near a location for Places and the Explore feed.
///
/// The fetcher uses `WMFArticleSearchDataController` and converts the result into `MWKLocationSearchResult` objects.
/// Remove this class when the legacy Places and Explore code is removed.
@objc(WMFLocationSearchFetcher)
public final class WMFLocationSearchFetcher: NSObject {

    private let dataController: WMFArticleSearchDataController

    @objc public override init() {
        dataController = WMFArticleSearchDataController.shared
        super.init()
    }

    public init(dataController: WMFArticleSearchDataController) {
        self.dataController = dataController
        super.init()
    }

    /// Fetch articles within 1 km of a location.
    @objc(fetchArticlesWithSiteURL:location:resultLimit:completion:failure:)
    public func fetchArticles(withSiteURL siteURL: URL, location: CLLocation, resultLimit: UInt, completion: @escaping (WMFLocationSearchResults) -> Void, failure: @escaping (Error) -> Void) {
        let region = CLCircularRegion(center: location.coordinate, radius: 1000, identifier: "")
        fetchArticles(withSiteURL: siteURL, in: region, matchingSearchTerm: nil, sortStyle: .none, resultLimit: resultLimit, completion: completion, failure: failure)
    }

    /// Fetch articles in a region. An optional search term filters the articles.
    @objc(fetchArticlesWithSiteURL:inRegion:matchingSearchTerm:sortStyle:resultLimit:completion:failure:)
    public func fetchArticles(withSiteURL siteURL: URL, in region: CLCircularRegion, matchingSearchTerm searchTerm: String?, sortStyle: WMFLocationSearchSortStyle, resultLimit: UInt, completion: @escaping (WMFLocationSearchResults) -> Void, failure: @escaping (Error) -> Void) {
        guard let languageCode = siteURL.wmf_languageCode else {
            failure(RequestError.invalidParameters)
            return
        }

        let languageVariantCode = siteURL.wmf_languageVariantCode
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        let dataController = self.dataController

        Task {
            do {
                let results = try await dataController.searchNearby(
                    project: project,
                    latitude: region.center.latitude,
                    longitude: region.center.longitude,
                    radius: region.radius,
                    term: searchTerm,
                    sortStyle: sortStyle.dataControllerSortStyle,
                    limit: Int(resultLimit)
                )

                guard !results.isEmpty else {
                    failure(WMFLocationSearchFetcher.noResultsError)
                    return
                }

                let locationResults = results.map { MWKLocationSearchResult(result: $0, languageVariantCode: languageVariantCode) }
                completion(WMFLocationSearchResults(searchSiteURL: siteURL, region: region, searchTerm: searchTerm, results: locationResults))
            } catch {
                // Network errors go to the caller. Every other error means that there are no results.
                if (error as NSError).domain == NSURLErrorDomain {
                    failure(error)
                } else {
                    failure(WMFLocationSearchFetcher.noResultsError)
                }
            }
        }
    }

    private static var noResultsError: NSError {
        let message = WMFLocalizedString("empty-no-search-results-message", value: "No results found", comment: "Shown when there are no search results")
        return NSError(domain: WMFLocationSearchErrorDomain, code: Int(WMFLocationSearchErrorCode.noResults.rawValue), userInfo: [NSLocalizedDescriptionKey: message])
    }
}
