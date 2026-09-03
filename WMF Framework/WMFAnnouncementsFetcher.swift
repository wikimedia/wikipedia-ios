import Foundation
import WMFData

/// Fetches announcements for the Explore feed and filters them for this app and the country of the user.
///
/// The fetcher uses `WMFAnnouncementsDataController` and converts the result into `WMFAnnouncement` objects
/// that the content group can archive. Remove this class when the Explore feed is removed.
@objc(WMFAnnouncementsFetcher)
public final class WMFAnnouncementsFetcher: NSObject {

    @objc(fetchAnnouncementsForURL:force:failure:success:)
    public func fetchAnnouncements(for siteURL: URL, force: Bool, failure: @escaping (Error) -> Void, success: @escaping ([WMFAnnouncement]) -> Void) {
        guard let languageCode = siteURL.wmf_languageCode else {
            failure(RequestError.invalidParameters)
            return
        }

        let languageVariantCode = siteURL.wmf_languageVariantCode
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))

        Task {
            do {
                let announcements = try await WMFAnnouncementsDataController.shared.fetchAnnouncements(project: project)
                let filtered = WMFAnnouncementsDataController.filter(announcements, countryCode: WMFAnnouncementsFetcher.geoIPCountryCode())
                success(filtered.map { WMFAnnouncement(announcement: $0, languageVariantCode: languageVariantCode) })
            } catch {
                failure(error)
            }
        }
    }

    /// Read the country code from the GeoIP cookie. The cookie value starts with the country code, for example `US:CA:...`.
    private static func geoIPCountryCode() -> String? {
        let storages = [Session.sharedCookieStorage, HTTPCookieStorage.shared]
        for storage in storages {
            guard let cookie = storage.cookies?.first(where: { $0.name.contains("GeoIP") }) else {
                continue
            }
            return cookie.value
        }
        return nil
    }
}
