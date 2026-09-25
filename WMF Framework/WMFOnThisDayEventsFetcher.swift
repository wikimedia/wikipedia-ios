import Foundation
import WMFData

/// Fetches the on-this-day events for the Explore feed.
///
/// The fetcher uses `WMFOnThisDayDataController` and converts the result into `WMFFeedOnThisDayEvent` objects.
/// Remove this class when the Explore feed is removed.
@objc(WMFOnThisDayEventsFetcher)
public final class WMFOnThisDayEventsFetcher: NSObject {

    /// The languages with an on-this-day feed.
    private static let supportedLanguages: Set<String> = ["en", "de", "sv", "fr", "es", "ru", "pt", "ar", "uk", "tr"]

    private let dataController: WMFOnThisDayDataController

    @objc public override init() {
        dataController = WMFOnThisDayDataController.shared
        super.init()
    }

    public init(dataController: WMFOnThisDayDataController) {
        self.dataController = dataController
        super.init()
    }

    @objc(isOnThisDaySupportedByLanguage:)
    public static func isOnThisDaySupported(by languageCode: String) -> Bool {
        return supportedLanguages.contains(languageCode)
    }

    /// Fetch the events for a month and a day.
    @objc(fetchOnThisDayEventsForURL:month:day:failure:success:)
    public func fetchOnThisDayEvents(forURL siteURL: URL, month: UInt, day: UInt, failure: @escaping (Error) -> Void, success: @escaping ([WMFFeedOnThisDayEvent]) -> Void) {
        guard let languageCode = siteURL.wmf_languageCode,
              WMFOnThisDayEventsFetcher.isOnThisDaySupported(by: languageCode),
              month >= 1, day >= 1 else {
            failure(RequestError.invalidParameters)
            return
        }

        let languageVariantCode = siteURL.wmf_languageVariantCode
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        let dataController = self.dataController

        Task {
            do {
                let response = try await dataController.fetchOnThisDay(project: project, month: Int(month), day: Int(day))
                success(response.events.map { WMFFeedOnThisDayEvent(event: $0, languageVariantCode: languageVariantCode) })
            } catch {
                failure(error)
            }
        }
    }
}
