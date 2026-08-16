import Foundation
import CoreLocation

public extension NSUserActivity {
    var wmf_placesCoordinate: CLLocationCoordinate2D? {
        guard let lat = userInfo?["WMFPlacesLatitude"] as? NSNumber,
              let lon = userInfo?["WMFPlacesLongitude"] as? NSNumber else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lon.doubleValue)
    }

    @objc var shouldSkipOnboarding: Bool {
        guard let path = webpageURL?.wikiResourcePath,
              let languageCode = webpageURL?.wmf_languageCode else {
            return false
        }

        let namespaceAndTitle = path.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        let namespace = namespaceAndTitle.0
        let title = namespaceAndTitle.1

        return namespace == .special && title == "ReadingLists"
    }
}
