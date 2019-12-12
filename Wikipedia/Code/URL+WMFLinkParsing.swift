import Foundation

extension CharacterSet {
    public static var wmf_articleTitlePathComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_URLArticleTitlePathComponentAllowed()
    }

    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
}

extension URL {
    
    /// Returns a new URL with the existing scheme replaced with the wikipedia:// scheme
    public var replacingSchemeWithWikipediaScheme: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "wikipedia"
        return components?.url
    }
    
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
    
    public var wmf_databaseKey: String? {
        return (self as NSURL).wmf_databaseKey
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
    
    public var canonical: URL {
        return (self as NSURL).wmf_canonical ?? self
    }
    
    public var wikiResourcePath: String? {
        return path.wikiResourcePath
    }
    
    public var wResourcePath: String? {
        return path.wResourcePath
    }
    
    public var namespace: PageNamespace? {
        guard let language = wmf_language else {
            return nil
        }
        return wikiResourcePath?.namespaceOfWikiResourcePath(with: language)
    }
    
    public var namespaceAndTitle: (namespace: PageNamespace, title: String)? {
        guard let language = wmf_language else {
            return nil
        }
        return wikiResourcePath?.namespaceAndTitleOfWikiResourcePath(with: language)
    }
}


extension NSRegularExpression {
    func firstMatch(in string: String) -> NSTextCheckingResult? {
        return firstMatch(in: string, options: [], range: string.fullRange)
    }
    
    func firstReplacementString(in string: String, template: String = "$1") -> String? {
        guard let result = firstMatch(in: string)
        else {
            return nil
        }
        return replacementString(for: result, in: string, offset: 0, template: template)
    }
}

extension String {
    static let namespaceRegex = try! NSRegularExpression(pattern: "^(.+?)_*:_*(.*)$")
    // Assumes the input is the remainder of a /wiki/ path
    func namespaceOfWikiResourcePath(with language: String) -> PageNamespace {
        guard let namespaceString = String.namespaceRegex.firstReplacementString(in: self) else {
            return .main
        }
        return WikipediaURLTranslations.commonNamespace(for: namespaceString, in: language) ?? .main
    }
    
    func namespaceAndTitleOfWikiResourcePath(with language: String) -> (namespace: PageNamespace, title: String) {
        guard let result = String.namespaceRegex.firstMatch(in: self) else {
            return (.main, self)
        }
        let namespaceString = String.namespaceRegex.replacementString(for: result, in: self, offset: 0, template: "$1")
        guard let namespace = WikipediaURLTranslations.commonNamespace(for: namespaceString, in: language) else {
            return (.main, self)
        }
        let title = String.namespaceRegex.replacementString(for: result, in: self, offset: 0, template: "$2")
        return (namespace, title)
    }
    
    static let wikiResourceRegex = try! NSRegularExpression(pattern: "^/wiki/(.+)$", options: .caseInsensitive)
    var wikiResourcePath: String? {
        return String.wikiResourceRegex.firstReplacementString(in: self)
    }
    
    static let wResourceRegex = try! NSRegularExpression(pattern: "^/w/(.+)$", options: .caseInsensitive)
    public var wResourcePath: String? {
        return String.wResourceRegex.firstReplacementString(in: self)
    }
    
    public var fullRange: NSRange {
        return NSRange(startIndex..<endIndex, in: self)
    }
}


@objc extension NSURL {
    // deprecated - use namespace methods
    @objc var wmf_isWikiResource: Bool {
        return (self as URL).wikiResourcePath != nil
    }
}

@objc extension NSString {
    // deprecated - use namespace methods
    @objc var wmf_isWikiResource: Bool {
        return (self as String).wikiResourcePath != nil
    }
    
    // deprecated - use swift methods
    @objc var wmf_pathWithoutWikiPrefix: String? {
        return (self as String).wikiResourcePath
    }
}
