import Foundation

@objc(RemoteNotificationLinks)
public class RemoteNotificationLinks: NSObject, NSSecureCoding, Codable {
    public static var supportsSecureCoding: Bool = true
    
    let primary: RemoteNotificationLink?
    let secondary: [RemoteNotificationLink]?

    init(primary: RemoteNotificationLink?, secondary: [RemoteNotificationLink]?) {
        self.primary = primary
        self.secondary = secondary
    }

    public required convenience init(coder decoder: NSCoder) {
        
        let primary = decoder.decodeObject(of: RemoteNotificationLink.self, forKey: "primary")
        let classes = [NSArray.classForCoder(), RemoteNotificationLink.classForCoder()]
        let secondary = decoder.decodeObject(of: classes, forKey: "secondary") as? [RemoteNotificationLink]
        self.init(primary: primary, secondary: secondary)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(primary, forKey: "primary")
        coder.encode(secondary, forKey: "secondary")
    }
}

@objc(RemoteNotificationLink)
public class RemoteNotificationLink: NSObject, NSSecureCoding, Codable {
    public static var supportsSecureCoding: Bool = true
    
    let type: String?
    let url: URL?
    let label: String?

    init(type: NSString?, url: URL?, label: NSString?) {
        self.type = type as String?
        self.url = url
        self.label = label as String?
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
