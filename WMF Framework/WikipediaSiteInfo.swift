import Foundation

@objc public class WikipediaSiteInfo: NSObject {
    static let maxage = 86400 // https://phabricator.wikimedia.org/T245033
    @objc public static let defaultRequestParameters: [String: Any] = [
        "action": "query",
        "meta": "siteinfo",
        "format": "json",
        "formatversion": "2",
        "maxage": maxage,
        "smaxage": maxage
    ]
}
