import Foundation

@objc(WMFAnalyticsContextProviding) public protocol AnalyticsContextProviding {
    var analyticsContext: String {
        get
    }
}

@objc(WMFAnalyticsContentTypeProviding) public protocol AnalyticsContentTypeProviding {
    var analyticsContentType: String {
        get
    }
}

@objc(WMFAnalyticsViewNameProviding) public protocol AnalyticsViewNameProviding {
    var analyticsName: String {
        get
    }
}

@objc(WMFAnalyticsValueProviding) public protocol AnalyticsValueProviding {
    var analyticsValue: NSNumber? {
        get
    }
}

public class AnalyticsContext: NSObject, AnalyticsContextProviding, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    let name: String
    
    public required init(stringLiteral value: StringLiteralType) {
        name = value
    }
    public required init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        name = value
    }
    public required init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        name = value
    }
    public var analyticsContext: String {
        return name
    }
}


public class AnalyticsContent: NSObject, AnalyticsContentTypeProviding, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String
    let type: String
    
    public required init(stringLiteral value: StringLiteralType) {
        type = value
    }
    public required init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        type = value
    }
    public required init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        type = value
    }
    
    @objc(initWithString:) public init(_ string: String) {
        type = string
    }
    
    @objc(initWithURL:) public init(_ url: URL) {
        type = url.host ?? AnalyticsContent.defaultContent
    }
    
    public var analyticsContentType: String {
        return type
    }
    
    public static let defaultContent = "unknown domain"
}

extension WMFArticle: AnalyticsContentTypeProviding {
    public var analyticsContentType: String {
        return AnalyticsContent(url?.host ?? AnalyticsContent.defaultContent).analyticsContentType
    }
}

extension NSString: AnalyticsContentTypeProviding {
    public var analyticsContentType: String {
        return self as String
    }
}

extension NSString: AnalyticsContextProviding {
    public var analyticsContext: String {
        return self as String
    }
}
