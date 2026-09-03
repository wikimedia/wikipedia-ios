import Foundation
import CoreLocation
import WMFData

/// A search result for the legacy search, Places and Explore code.
///
/// This class is a temporary bridge. WMFData decodes the result into a `WMFArticleSearchResult` struct.
/// Places archives this class inside its recent searches with NSSecureCoding. The class name and the
/// coding keys are the same as the old Mantle model, so archives from earlier app versions still decode.
/// Remove this class when the legacy search and Explore code is removed.
@objc(MWKSearchResult)
@objcMembers
public class MWKSearchResult: NSObject, NSSecureCoding {

    public let articleID: Int
    public let revID: Int
    public let title: String?
    /// The display title without HTML.
    public let displayTitle: String?
    private let storedDisplayTitleHTML: String?
    public let wikidataDescription: String?
    public let extract: String?
    public private(set) var thumbnailURL: URL?
    public let index: NSNumber?
    public let titleNamespace: NSNumber?
    public var viewCounts: [NSNumber]?
    /// The location from the first set of coordinates in the response.
    public let location: CLLocation?
    public var geoDimension: NSNumber?
    public var geoType: NSNumber?

    /// The display title with HTML. Falls back to the plain display title when the HTML title is empty.
    public var displayTitleHTML: String? {
        if let storedDisplayTitleHTML, !storedDisplayTitleHTML.isEmpty {
            return storedDisplayTitleHTML
        }
        return displayTitle
    }

    public init(articleID: Int, revID: Int, title: String?, displayTitle: String?, displayTitleHTML: String?, wikidataDescription: String?, extract: String?, thumbnailURL: URL?, index: NSNumber?, titleNamespace: NSNumber?, location: CLLocation?) {
        self.articleID = articleID
        self.revID = revID
        self.title = title
        self.displayTitle = displayTitle
        self.storedDisplayTitleHTML = displayTitleHTML
        self.wikidataDescription = wikidataDescription
        self.extract = extract
        self.thumbnailURL = thumbnailURL
        self.index = index
        self.titleNamespace = titleNamespace
        self.location = location
        super.init()
    }

    /// Create the bridge object from the WMFData model.
    /// - Parameter languageVariantCode: The language variant of the site. The initializer sets it on the thumbnail URL.
    public init(result: WMFArticleSearchResult, languageVariantCode: String?) {
        let displayTitleHTML = result.displayTitle ?? result.title
        articleID = result.pageID
        revID = result.revisionID ?? 0
        title = result.title
        displayTitle = (displayTitleHTML as NSString).wmf_stringByRemovingHTML()
        storedDisplayTitleHTML = displayTitleHTML
        wikidataDescription = result.description
        extract = result.extract.map { ($0 as NSString).wmf_summaryFromText() }
        thumbnailURL = result.thumbnailURL
        index = result.index.map { NSNumber(value: $0) }
        titleNamespace = NSNumber(value: result.namespace)
        if let coordinate = result.coordinate {
            location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geoDimension = coordinate.dimension.map { NSNumber(value: $0) }
            geoType = MWKSearchResult.geoType(from: coordinate.type).map { NSNumber(value: $0.rawValue) }
        } else {
            location = nil
        }
        super.init()
        propagateLanguageVariantCode(languageVariantCode)
    }

    @objc(articleURLForSiteURL:)
    public func articleURL(forSiteURL siteURL: URL?) -> URL? {
        guard let siteURL, let title else {
            return nil
        }
        return siteURL.wmf_URL(withTitle: title)
    }

    /// Set the language variant code on the thumbnail URL. The content group calls this method after it decodes the object.
    public func propagateLanguageVariantCode(_ languageVariantCode: String?) {
        thumbnailURL?.wmf_languageVariantCode = languageVariantCode
    }

    /// Convert the coordinate type from the API to the geo type of the article.
    static func geoType(from typeString: String?) -> WMFGeoType? {
        guard var type = typeString?.lowercased() else {
            return nil
        }
        if type.hasPrefix("city") {
            type = "city"
        }
        let lookup: [String: WMFGeoType] = [
            "country": .country,
            "satellite": .satellite,
            "adm1st": .adm1st,
            "adm2nd": .adm2nd,
            "adm3rd": .adm3rd,
            "city": .city,
            "airport": .airport,
            "mountain": .mountain,
            "isle": .isle,
            "waterbody": .waterBody,
            "forest": .forest,
            "river": .river,
            "glacier": .glacier,
            "event": .event,
            "edu": .edu,
            "pass": .pass,
            "railwaystation": .railwayStation,
            "landmark": .landmark
        ]
        return lookup[type]
    }

    // MARK: - NSSecureCoding

    public class var supportsSecureCoding: Bool { true }

    private enum Key {
        static let articleID = "articleID"
        static let revID = "revID"
        static let title = "title"
        static let displayTitle = "displayTitle"
        static let displayTitleHTML = "displayTitleHTML"
        static let wikidataDescription = "wikidataDescription"
        static let extract = "extract"
        static let thumbnailURL = "thumbnailURL"
        static let index = "index"
        static let titleNamespace = "titleNamespace"
        static let viewCounts = "viewCounts"
        static let location = "location"
        static let geoDimension = "geoDimension"
        static let geoType = "geoType"
    }

    public required init?(coder: NSCoder) {
        articleID = coder.decodeObject(of: NSNumber.self, forKey: Key.articleID)?.intValue ?? 0
        revID = coder.decodeObject(of: NSNumber.self, forKey: Key.revID)?.intValue ?? 0
        title = coder.decodeObject(of: NSString.self, forKey: Key.title) as String?
        displayTitle = coder.decodeObject(of: NSString.self, forKey: Key.displayTitle) as String?
        storedDisplayTitleHTML = coder.decodeObject(of: NSString.self, forKey: Key.displayTitleHTML) as String?
        wikidataDescription = coder.decodeObject(of: NSString.self, forKey: Key.wikidataDescription) as String?
        extract = coder.decodeObject(of: NSString.self, forKey: Key.extract) as String?
        thumbnailURL = coder.decodeObject(of: NSURL.self, forKey: Key.thumbnailURL) as URL?
        index = coder.decodeObject(of: NSNumber.self, forKey: Key.index)
        titleNamespace = coder.decodeObject(of: NSNumber.self, forKey: Key.titleNamespace)
        viewCounts = coder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: Key.viewCounts) as? [NSNumber]
        location = coder.decodeObject(of: CLLocation.self, forKey: Key.location)
        geoDimension = coder.decodeObject(of: NSNumber.self, forKey: Key.geoDimension)
        geoType = coder.decodeObject(of: NSNumber.self, forKey: Key.geoType)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(NSNumber(value: articleID), forKey: Key.articleID)
        coder.encode(NSNumber(value: revID), forKey: Key.revID)
        coder.encode(title, forKey: Key.title)
        coder.encode(displayTitle, forKey: Key.displayTitle)
        coder.encode(storedDisplayTitleHTML, forKey: Key.displayTitleHTML)
        coder.encode(wikidataDescription, forKey: Key.wikidataDescription)
        coder.encode(extract, forKey: Key.extract)
        coder.encode(thumbnailURL, forKey: Key.thumbnailURL)
        coder.encode(index, forKey: Key.index)
        coder.encode(titleNamespace, forKey: Key.titleNamespace)
        coder.encode(viewCounts, forKey: Key.viewCounts)
        coder.encode(location, forKey: Key.location)
        coder.encode(geoDimension, forKey: Key.geoDimension)
        coder.encode(geoType, forKey: Key.geoType)
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MWKSearchResult else {
            return false
        }
        return articleID == other.articleID
            && revID == other.revID
            && title == other.title
            && displayTitle == other.displayTitle
            && wikidataDescription == other.wikidataDescription
            && thumbnailURL == other.thumbnailURL
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(articleID)
        hasher.combine(title)
        return hasher.finalize()
    }
}

/// A search result with the distance from the search coordinate.
@objc(MWKLocationSearchResult)
@objcMembers
public final class MWKLocationSearchResult: MWKSearchResult {

    /// The distance in meters between the result and the search coordinate.
    public let distanceFromQueryCoordinates: CLLocationDistance

    public override init(result: WMFArticleSearchResult, languageVariantCode: String?) {
        distanceFromQueryCoordinates = result.coordinate?.distance ?? 0
        super.init(result: result, languageVariantCode: languageVariantCode)
    }

    private static let distanceKey = "distanceFromQueryCoordinates"

    public override class var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        distanceFromQueryCoordinates = coder.decodeObject(of: NSNumber.self, forKey: MWKLocationSearchResult.distanceKey)?.doubleValue ?? 0
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(NSNumber(value: distanceFromQueryCoordinates), forKey: MWKLocationSearchResult.distanceKey)
    }
}
