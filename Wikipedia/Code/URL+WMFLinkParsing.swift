import Foundation

extension CharacterSet {
    static var wmf_articleTitlePathComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_URLArticleTitlePathComponentAllowed()
    }

    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
}

extension URL {
    public var wmf_percentEscapedTitle: String? {
        return wmf_titleWithUnderscores?.addingPercentEncoding(withAllowedCharacters: .wmf_articleTitlePathComponentAllowed)
    }
    
    public var wmf_language: String? {
        return (self as NSURL).wmf_language
    }
    
    public var wmf_title: String? {
        return (self as NSURL).wmf_title
    }
    
    public var wmf_titleWithUnderscores: String? {
        return (self as NSURL).wmf_titleWithUnderscores
    }
    
    public var wmf_articleDatabaseKey: String? {
        return (self as NSURL).wmf_articleDatabaseKey
    }
    
    public var wmf_site: URL? {
        return (self as NSURL).wmf_site
    }
    
    public func wmf_URL(withTitle title: String) -> URL? {
        return (self as NSURL).wmf_URL(withTitle: title)
    }
    
    public func wmf_URL(withFragment fragment: String) -> URL? {
        return (self as NSURL).wmf_URL(withFragment: fragment)
    }
    
    public func wmf_URL(withPath path: String, isMobile: Bool) -> URL? {
        return (self as NSURL).wmf_URL(withPath: path, isMobile: isMobile)
    }
    
    public var wmf_isNonStandardURL: Bool {
        return (self as NSURL).wmf_isNonStandardURL
    }

    public var wmf_wiki: String? {
        return wmf_language?.replacingOccurrences(of: "-", with: "_").appending("wiki")
    }
    
    fileprivate func wmf_URLForSharing(with wprov: String) -> URL {
        let queryItems = [URLQueryItem(name: "wprov", value: wprov)]
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? self
    }
    
    // URL for sharing text only
    public var wmf_URLForTextSharing: URL {
        return wmf_URLForSharing(with: "sfti1")
    }
    
    // URL for sharing that includes an image (for example, Share-a-fact)
    public var wmf_URLForImageSharing: URL {
        return wmf_URLForSharing(with: "sfii1")
    }
}
