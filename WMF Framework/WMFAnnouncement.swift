import Foundation
import WMFData

/// An announcement that the Explore feed stores in a content group.
///
/// This class is a temporary bridge. WMFData decodes the announcement into a `WMFFeedAnnouncement` struct.
/// The Explore feed archives this class into Core Data with NSSecureCoding. The class name and the
/// coding keys are the same as the old Mantle model, so archives from earlier app versions still decode.
/// Remove this class when the Explore feed is removed.
@objc(WMFAnnouncement)
@objcMembers
public final class WMFAnnouncement: NSObject, NSSecureCoding {

    public let identifier: String?
    public let type: String?
    public let startTime: Date?
    public let endTime: Date?
    public let platforms: [String]?
    public let countries: [String]?
    public let placement: String?
    public private(set) var imageURL: URL?
    public let imageHeight: NSNumber?
    public let text: String?
    public let actionTitle: String?
    public private(set) var actionURL: URL?
    public let actionURLString: String?
    public let captionHTML: String?
    public let negativeText: String?
    public let readingListSyncEnabled: NSNumber?
    public let loggedIn: NSNumber?
    public let beta: NSNumber?
    public let domain: String?
    public let articleTitles: [String]?
    public let percentReceivingExperiment: NSNumber?
    public let displayDelay: NSNumber?

    /// Create the bridge object from the WMFData model.
    /// - Parameter languageVariantCode: The language variant of the site. The initializer sets it on the URLs.
    public init(announcement: WMFFeedAnnouncement, languageVariantCode: String?) {
        identifier = announcement.identifier
        type = announcement.type
        startTime = announcement.startTime
        endTime = announcement.endTime
        platforms = announcement.platforms
        countries = announcement.countries
        placement = announcement.placement
        imageURL = announcement.imageURL
        imageHeight = announcement.imageHeight.map { NSNumber(value: $0) }
        text = announcement.text
        actionTitle = announcement.actionTitle
        actionURL = announcement.actionURL
        actionURLString = announcement.actionURLString
        captionHTML = announcement.captionHTML
        negativeText = announcement.negativeText
        readingListSyncEnabled = announcement.readingListSyncEnabled.map { NSNumber(value: $0) }
        loggedIn = announcement.loggedIn.map { NSNumber(value: $0) }
        beta = announcement.beta.map { NSNumber(value: $0) }
        domain = announcement.domain
        articleTitles = announcement.articleTitles
        percentReceivingExperiment = announcement.percentReceivingExperiment.map { NSNumber(value: $0) }
        displayDelay = announcement.displayDelay.map { NSNumber(value: $0) }
        super.init()
        propagateLanguageVariantCode(languageVariantCode)
    }

    // MARK: - Language variant

    /// Set the language variant code on the URL properties. The content group calls this method after it decodes the object.
    public func propagateLanguageVariantCode(_ languageVariantCode: String?) {
        imageURL?.wmf_languageVariantCode = languageVariantCode
        actionURL?.wmf_languageVariantCode = languageVariantCode
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    private enum Key {
        static let identifier = "identifier"
        static let type = "type"
        static let startTime = "startTime"
        static let endTime = "endTime"
        static let platforms = "platforms"
        static let countries = "countries"
        static let placement = "placement"
        static let imageURL = "imageURL"
        static let imageHeight = "imageHeight"
        static let text = "text"
        static let actionTitle = "actionTitle"
        static let actionURL = "actionURL"
        static let actionURLString = "actionURLString"
        static let captionHTML = "captionHTML"
        static let negativeText = "negativeText"
        static let readingListSyncEnabled = "readingListSyncEnabled"
        static let loggedIn = "loggedIn"
        static let beta = "beta"
        static let domain = "domain"
        static let articleTitles = "articleTitles"
        static let percentReceivingExperiment = "percentReceivingExperiment"
        static let displayDelay = "displayDelay"
    }

    public init?(coder: NSCoder) {
        identifier = coder.decodeObject(of: NSString.self, forKey: Key.identifier) as String?
        type = coder.decodeObject(of: NSString.self, forKey: Key.type) as String?
        startTime = coder.decodeObject(of: NSDate.self, forKey: Key.startTime) as Date?
        endTime = coder.decodeObject(of: NSDate.self, forKey: Key.endTime) as Date?
        platforms = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: Key.platforms) as? [String]
        countries = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: Key.countries) as? [String]
        placement = coder.decodeObject(of: NSString.self, forKey: Key.placement) as String?
        imageURL = coder.decodeObject(of: NSURL.self, forKey: Key.imageURL) as URL?
        imageHeight = coder.decodeObject(of: NSNumber.self, forKey: Key.imageHeight)
        text = coder.decodeObject(of: NSString.self, forKey: Key.text) as String?
        actionTitle = coder.decodeObject(of: NSString.self, forKey: Key.actionTitle) as String?
        actionURLString = coder.decodeObject(of: NSString.self, forKey: Key.actionURLString) as String?
        actionURL = (coder.decodeObject(of: NSURL.self, forKey: Key.actionURL) as URL?) ?? actionURLString.flatMap { URL(string: $0) }
        captionHTML = coder.decodeObject(of: NSString.self, forKey: Key.captionHTML) as String?
        negativeText = coder.decodeObject(of: NSString.self, forKey: Key.negativeText) as String?
        readingListSyncEnabled = coder.decodeObject(of: NSNumber.self, forKey: Key.readingListSyncEnabled)
        loggedIn = coder.decodeObject(of: NSNumber.self, forKey: Key.loggedIn)
        beta = coder.decodeObject(of: NSNumber.self, forKey: Key.beta)
        domain = coder.decodeObject(of: NSString.self, forKey: Key.domain) as String?
        articleTitles = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: Key.articleTitles) as? [String]
        percentReceivingExperiment = coder.decodeObject(of: NSNumber.self, forKey: Key.percentReceivingExperiment)
        displayDelay = coder.decodeObject(of: NSNumber.self, forKey: Key.displayDelay)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier, forKey: Key.identifier)
        coder.encode(type, forKey: Key.type)
        coder.encode(startTime, forKey: Key.startTime)
        coder.encode(endTime, forKey: Key.endTime)
        coder.encode(platforms, forKey: Key.platforms)
        coder.encode(countries, forKey: Key.countries)
        coder.encode(placement, forKey: Key.placement)
        coder.encode(imageURL, forKey: Key.imageURL)
        coder.encode(imageHeight, forKey: Key.imageHeight)
        coder.encode(text, forKey: Key.text)
        coder.encode(actionTitle, forKey: Key.actionTitle)
        coder.encode(actionURL, forKey: Key.actionURL)
        coder.encode(actionURLString, forKey: Key.actionURLString)
        coder.encode(captionHTML, forKey: Key.captionHTML)
        coder.encode(negativeText, forKey: Key.negativeText)
        coder.encode(readingListSyncEnabled, forKey: Key.readingListSyncEnabled)
        coder.encode(loggedIn, forKey: Key.loggedIn)
        coder.encode(beta, forKey: Key.beta)
        coder.encode(domain, forKey: Key.domain)
        coder.encode(articleTitles, forKey: Key.articleTitles)
        coder.encode(percentReceivingExperiment, forKey: Key.percentReceivingExperiment)
        coder.encode(displayDelay, forKey: Key.displayDelay)
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WMFAnnouncement else {
            return false
        }
        return identifier == other.identifier
            && type == other.type
            && startTime == other.startTime
            && endTime == other.endTime
            && placement == other.placement
            && text == other.text
            && actionTitle == other.actionTitle
            && actionURLString == other.actionURLString
            && imageURL == other.imageURL
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        hasher.combine(text)
        return hasher.finalize()
    }
}
