import MapKit

enum PlaceSearchType: UInt {
    case text
    case location
    case nearby
}

enum PlaceFilterType: UInt {
    case top
    case saved
    
    var stringValue : String {
        switch self {
        case .top: return "top";
        case .saved: return "saved";
        }
    }
}

enum PlaceSearchOrigin: UInt {
    case user
    case system
}

enum PlaceSearchError: Error {
    case deserialization(object: NSCoding?)
}

extension MKCoordinateRegion {
    var stringValue: String {
        return String(format: "%.3f,%.3f|%.3f,%.3f", center.latitude, center.longitude, span.latitudeDelta, span.longitudeDelta)
    }
}

struct PlaceSearch {
    let filter: PlaceFilterType
    let type: PlaceSearchType
    let origin: PlaceSearchOrigin
    let sortStyle: WMFLocationSearchSortStyle
    let string: String?
    var region: MKCoordinateRegion?
    let localizedDescription: String?
    let searchResult: MWKSearchResult?
    var needsWikidataQuery: Bool = false
    let siteURL: URL?

    init(filter: PlaceFilterType, type: PlaceSearchType, origin: PlaceSearchOrigin, sortStyle: WMFLocationSearchSortStyle, string: String?, region: MKCoordinateRegion?, localizedDescription: String?, searchResult: MWKSearchResult?, siteURL: URL? = nil) {
        self.filter = filter
        self.type = type
        self.origin = origin
        self.sortStyle = sortStyle
        self.string = string
        self.region = region
        self.localizedDescription = localizedDescription
        self.searchResult = searchResult
        self.needsWikidataQuery = type == .location && searchResult != nil
        self.siteURL = siteURL
    }
    
    
    var key: String {
        get {
            var key = "\(type.rawValue)|\(filter.rawValue)|\(sortStyle.rawValue)"
            if let searchResult = searchResult {
                if let siteURL = siteURL, let articleURL = searchResult.articleURL(forSiteURL: siteURL), let articleKey = articleURL.wmf_databaseKey {
                    key.append("|\(articleKey)")
                } else {
                    let lang = siteURL?.wmf_language ?? ""
                    key.append("|\(lang)|\(searchResult.displayTitle?.precomposedStringWithCanonicalMapping ?? "")")
                }
                
            } else if let string = string {
                key.append("|\(string.lowercased().precomposedStringWithCanonicalMapping)")
            }
            return key
        }
    }
    
    var dictionaryValue: [String: NSCoding] {
        get {
            var dictionary: [String: NSCoding] = [:]
            dictionary["type"] = NSNumber(value: type.rawValue)
            dictionary["filter"] = NSNumber(value: filter.rawValue)
            dictionary["origin"] = NSNumber(value: origin.rawValue)
            dictionary["sortStyle"] = NSNumber(value: sortStyle.rawValue)
            if let string = string {
                dictionary["string"] = string as NSString
            }
            if let region = region {
                dictionary["lat"] = NSNumber(value: region.center.latitude)
                dictionary["lon"] = NSNumber(value: region.center.longitude)
                dictionary["latd"] = NSNumber(value: region.span.latitudeDelta)
                dictionary["lond"] = NSNumber(value: region.span.longitudeDelta)
            }
            if let localizedDescription = localizedDescription {
                dictionary["localizedDescription"] = localizedDescription as NSString
            }
            if let result = searchResult {
                dictionary["searchResult"] = result
            }
            if let siteURL = siteURL {
                dictionary["siteURL"] = siteURL.absoluteString as NSString
            }
            return dictionary
        }
    }
    
    init?(dictionary: [String: Any]) {
        guard let filterNumber = dictionary["filter"] as? NSNumber,
            let filter = PlaceFilterType(rawValue: filterNumber.uintValue),
            let typeNumber = dictionary["type"] as? NSNumber,
            let type = PlaceSearchType(rawValue: typeNumber.uintValue),
            let originNumber = dictionary["origin"] as? NSNumber,
            let origin = PlaceSearchOrigin(rawValue: originNumber.uintValue),
            let sortStyleNumber = dictionary["sortStyle"] as? NSNumber else {
                return nil
        }
        self.filter = filter
        self.type = type
        self.origin = origin
        let sortStyle = WMFLocationSearchSortStyle(rawValue: sortStyleNumber.uintValue) ?? .none
        self.sortStyle = sortStyle
        
        self.string = dictionary["string"] as? String
        if let lat = dictionary["lat"] as? NSNumber,
            let lon = dictionary["lon"] as? NSNumber,
            let latd = dictionary["latd"] as? NSNumber,
            let lond = dictionary["lond"] as? NSNumber {
            let coordinate = CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lon.doubleValue)
            let span = MKCoordinateSpan(latitudeDelta: latd.doubleValue, longitudeDelta: lond.doubleValue)
            self.region = MKCoordinateRegion(center: coordinate, span: span)
        } else {
            self.region = nil
        }
        self.searchResult = dictionary["searchResult"] as? MWKSearchResult
        self.localizedDescription = dictionary["localizedDescription"] as? String
        if let siteURLString = dictionary["siteURL"] as? String {
            self.siteURL = URL(string: siteURLString)
        } else {
            self.siteURL = nil
        }
    }
    
    init?(object: NSCoding?) {
        guard let object = object as? NSObject,
            let filterNumber = object.value(forKey: "filter") as? NSNumber,
            let filter = PlaceFilterType(rawValue: filterNumber.uintValue),
            let typeNumber = object.value(forKey: "type") as? NSNumber,
            let type = PlaceSearchType(rawValue: typeNumber.uintValue),
            let originNumber = object.value(forKey: "origin") as? NSNumber,
            let origin = PlaceSearchOrigin(rawValue: originNumber.uintValue),
            let sortStyleNumber = object.value(forKey: "sortStyle") as? NSNumber else {
                return nil
        }
        self.filter = filter
        self.type = type
        self.origin = origin
        let sortStyle = WMFLocationSearchSortStyle(rawValue: sortStyleNumber.uintValue) ?? .none
        self.sortStyle = sortStyle
        
        self.string = object.value(forKey: "string") as? String
        if let lat = object.value(forKey: "lat") as? NSNumber,
            let lon = object.value(forKey: "lon") as? NSNumber,
            let latd = object.value(forKey: "latd") as? NSNumber,
            let lond = object.value(forKey: "lond") as? NSNumber {
            let coordinate = CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: lon.doubleValue)
            let span = MKCoordinateSpan(latitudeDelta: latd.doubleValue, longitudeDelta: lond.doubleValue)
            self.region = MKCoordinateRegion(center: coordinate, span: span)
        } else {
            self.region = nil
        }
        self.searchResult = object.value(forKey: "searchResult") as? MWKSearchResult
        self.localizedDescription = object.value(forKey: "localizedDescription") as? String
        if let siteURLString = object.value(forKey: "siteURL") as? String {
            self.siteURL = URL(string: siteURLString)
        } else {
            self.siteURL = nil
        }
    }
}
