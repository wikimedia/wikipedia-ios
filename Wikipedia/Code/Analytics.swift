import Foundation

public class AnalyticsContext: NSObject, WMFAnalyticsContextProviding, ExpressibleByStringLiteral {
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
    public func analyticsContext() -> String {
        return name
    }
}


public class AnalyticsContent: NSObject, WMFAnalyticsContentTypeProviding, ExpressibleByStringLiteral {
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
    
    public func analyticsContentType() -> String {
        return type
    }
    
    public static let defaultContent = "unknown domain"
}

extension WMFArticle: WMFAnalyticsContentTypeProviding {
    public func analyticsContentType() -> String {
        return AnalyticsContent(url?.host ?? AnalyticsContent.defaultContent).analyticsContentType()
    }
}
