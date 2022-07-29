import Foundation

@objc(RemoteNotificationLinks)
public class RemoteNotificationLinks: NSObject, NSSecureCoding, Codable {
    public static var supportsSecureCoding: Bool = true
    
    let primary: RemoteNotificationLink?
    let secondary: [RemoteNotificationLink]?
    let legacyPrimary: RemoteNotificationLink?

    init(primary: RemoteNotificationLink?, secondary: [RemoteNotificationLink]?, legacyPrimary: RemoteNotificationLink?) {
        self.primary = primary
        self.secondary = secondary
        self.legacyPrimary = legacyPrimary
    }

    public required convenience init(coder decoder: NSCoder) {
        
        let primary = decoder.decodeObject(of: RemoteNotificationLink.self, forKey: "primary")
        let classes = [NSArray.classForCoder(), RemoteNotificationLink.classForCoder()]
        let secondary = decoder.decodeObject(of: classes, forKey: "secondary") as? [RemoteNotificationLink]
        let legacyPrimary = decoder.decodeObject(of: RemoteNotificationLink.self, forKey: "legacyPrimary")
        self.init(primary: primary, secondary: secondary, legacyPrimary: legacyPrimary)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(primary, forKey: "primary")
        coder.encode(secondary, forKey: "secondary")
        coder.encode(legacyPrimary, forKey: "legacyPrimary")
    }
}

@objc(RemoteNotificationLink)
public final class RemoteNotificationLink: NSObject, NSSecureCoding, Codable {
    public static var supportsSecureCoding: Bool = true
    
    let type: String?
    public let url: URL?
    public let label: String?

    init(type: NSString?, url: URL?, label: NSString?) {
        self.type = type as String?
        self.url = url
        self.label = label as String?
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        type = try? values.decode(String.self, forKey: .type)
        
        let urlString = try? values.decode(String.self, forKey: .url)
        if var urlString = urlString {
            
            // If there's a fragment, it may not be encoded from the API, thus URLs and URLComponents won't instantiate.
            // Manually encoding it here.
            // https://phabricator.wikimedia.org/T307604
            if let firstHashIndex = urlString.firstIndex(of: "#") {
                let preFragment = urlString.prefix(upTo: firstHashIndex)
                let nextIndex = urlString.index(firstHashIndex, offsetBy: 1)
                let fragment = urlString.suffix(from: nextIndex)
                
                let unallowedFragmentCharacters = CharacterSet.urlFragmentAllowed.inverted
                if fragment.rangeOfCharacter(from: unallowedFragmentCharacters) != nil {
                    urlString = preFragment + "#" + (fragment.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? "")
                }
            }
            
            url = URL(string: urlString)
        } else {
            url = nil
        }
        
        label = try? values.decode(String.self, forKey: .label)
    }

    public required convenience init(coder decoder: NSCoder) {
        let type = decoder.decodeObject(of: NSString.self, forKey: "type")
        let urlString = decoder.decodeObject(of: NSString.self, forKey: "url")
        let label = decoder.decodeObject(of: NSString.self, forKey: "label")
        let url = URL(string: urlString as String? ?? "")
        self.init(type: type, url: url, label: label)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(type, forKey: "type")
        let urlString = url?.absoluteString
        coder.encode(urlString, forKey: "url")
        coder.encode(label, forKey: "label")
    }
}
