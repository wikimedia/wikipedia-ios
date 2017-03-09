import Foundation

class AnalyticsContext: NSObject, WMFAnalyticsContextProviding, ExpressibleByStringLiteral {
    typealias StringLiteralType = String
    typealias UnicodeScalarLiteralType = String
    typealias ExtendedGraphemeClusterLiteralType = String
    let name: String
    
    required init(stringLiteral value: StringLiteralType) {
        name = value
    }
    required init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        name = value
    }
    required init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        name = value
    }
    func analyticsContext() -> String {
        return name
    }
}

extension WMFArticle: WMFAnalyticsContentTypeProviding {
    public func analyticsContentType() -> String {
        return url?.host ?? "unkown domain"
    }
}
