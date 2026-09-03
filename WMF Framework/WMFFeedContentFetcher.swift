import Foundation
import WMFData

/// Fetches the feed content of one day for the Explore feed.
///
/// The fetcher uses `WMFFeedDataController` and converts the result into `WMFFeedDayResponse`.
/// Remove this class when the Explore feed is removed.
@objc(WMFFeedContentFetcher)
public final class WMFFeedContentFetcher: NSObject {

    /// The number of seconds that the feed content stays fresh. The value is 5 hours.
    private static let minimumMaxAge = 18000

    private let dataController: any WMFFeedDataControlling

    @objc public override init() {
        dataController = WMFFeedDataController.shared
        super.init()
    }

    public init(dataController: any WMFFeedDataControlling) {
        self.dataController = dataController
        super.init()
    }

    /// The URL of the feed content for a site and a date. The widget uses this URL as a cache key.
    @objc(feedContentURLForSiteURL:onDate:configuration:)
    public static func feedContentURL(forSiteURL siteURL: URL, on date: Date?, configuration: Configuration) -> URL? {
        var path = ["feed", "featured"]
        if let date {
            path += [
                DateFormatter.wmf_year().string(from: date),
                DateFormatter.wmf_month().string(from: date),
                DateFormatter.wmf_day().string(from: date)
            ]
        }
        return configuration.feedContentAPIURLForURL(siteURL, appending: path)
    }

    /// Fetch the feed content for a site and a date.
    @objc(fetchFeedContentForURL:date:force:failure:success:)
    public func fetchFeedContent(forURL siteURL: URL, date: Date, force: Bool, failure: @escaping (Error) -> Void, success: @escaping (WMFFeedDayResponse) -> Void) {
        guard let languageCode = siteURL.wmf_languageCode else {
            failure(RequestError.invalidParameters)
            return
        }

        let languageVariantCode = siteURL.wmf_languageVariantCode
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        let dataController = self.dataController

        Task {
            do {
                let response = try await dataController.fetchFeed(project: project, date: date)
                success(WMFFeedDayResponse(response: response, maxAge: WMFFeedContentFetcher.minimumMaxAge, languageVariantCode: languageVariantCode))
            } catch {
                failure(error)
            }
        }
    }
}
