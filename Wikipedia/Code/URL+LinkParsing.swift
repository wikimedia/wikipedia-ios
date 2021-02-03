import Foundation

extension URL {
    /// Returns a new URL with the existing scheme replaced with the wikipedia:// scheme
    public var replacingSchemeWithWikipediaScheme: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "wikipedia"
        return components?.wmf_URLWithLanguageVariantCode(wmf_languageVariantCode)
    }
    
    /// Returns the percent encoded page title to handle titles with / characters
    public var percentEncodedPageTitleForPathComponents: String? {
        return wmf_title?.percentEncodedPageTitleForPathComponents
    }
    
    /// Encodes the page title to handle titles with forward slash characters when splitting path components.
    /// The callee should be a standardized page URL generated with wmf_databaseURL, non-article namespaces are OK
    /// For example, https://en.wikipedia.org/wiki/G/O_Media becomes https://en.wikipedia.org/wiki/G%2FO_Media
    public var encodedWikiURL: URL? {
        guard let percentEncodedTitle = percentEncodedPageTitleForPathComponents else {
            assert(false, "encodedWikiURL potentially called on a non-wiki URL")
            return nil
        }
        let encodedPathComponents = ["wiki", percentEncodedTitle]
        var encodedURLComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        encodedURLComponents?.replacePercentEncodedPathWithPathComponents(encodedPathComponents)
        return encodedURLComponents?.wmf_URLWithLanguageVariantCode(wmf_languageVariantCode)
    }
    
    /// Resolves a relative href from a wiki page against the callee.
    /// The callee should be a standardized page URL generated with wmf_databaseURL, non-article namespaces are OK
    public func resolvingRelativeWikiHref(_ href: String) -> URL? {
        let urlComponentsString: String

        /// The link is sometimes encoded, and sometimes unencoded. (In some cases, this depends on whether an editor put added an escaped or unescaped version of the URL.) So we remove any potential encoding, so that we can be assured we are starting with an unencoded string.
        let hrefWithoutEncoding = href.removingPercentEncoding ?? href

        if hrefWithoutEncoding.hasPrefix(".") || hrefWithoutEncoding.hasPrefix("/") {
            urlComponentsString = hrefWithoutEncoding.addingPercentEncoding(withAllowedCharacters: .relativePathAndFragmentAllowed) ?? href
        } else {
            urlComponentsString = hrefWithoutEncoding
        }
        let components = URLComponents(string: urlComponentsString)
        // Encode this URL to handle titles with forward slashes, otherwise URLComponents thinks they're separate path components
        let encodedBaseURL = encodedWikiURL
        var resolvedURL = components?.url(relativeTo: encodedBaseURL)?.absoluteURL
        resolvedURL?.wmf_languageVariantCode = wmf_languageVariantCode
        return resolvedURL
    }
    
    public var wmf_language: String? {
        return (self as NSURL).wmf_language
    }
    
    public var wmf_languageVariantCode: String? {
        get { (self as NSURL).wmf_languageVariantCode }
        set { (self as NSURL).wmf_languageVariantCode = newValue }
    }
    
    public var wmf_contentLanguageCode: String? {
        return (self as NSURL).wmf_contentLanguageCode
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
    
    public var wmf_inMemoryKey: WMFInMemoryURLKey? {
        return (self as NSURL).wmf_inMemoryKey
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
        return components?.wmf_URLWithLanguageVariantCode(wmf_languageVariantCode) ?? self
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
    
    public var articleTalkPage: URL? {
        guard
            let namespaceAndTitle = namespaceAndTitle,
            namespaceAndTitle.namespace == .main
        else {
            return nil
        }
        return wmf_URL(withTitle: "Talk:\(namespaceAndTitle.title)")
    }
    
    public var isPreviewable: Bool {
        return (self as NSURL).wmf_isPeekable
    }
    
    /// Returns true if this is a URL for a media file hosted on Wikimedia Commons
    private var isHostedFileLink: Bool {
        return host?.lowercased() == Configuration.Domain.uploads
    }
    
    /// Returns true if this is a URL with an extension indicating that it's ogg audio
    private var hasOggAudioExtension: Bool {
        let lowercasedExtension = pathExtension.lowercased()
        return lowercasedExtension == "ogg" || lowercasedExtension == "oga"
    }
    
    /// Returns true if this is a URL for an audio file hosted on the Wikimedia uploads host
    public var isWikimediaHostedAudioFileLink: Bool {
        return isHostedFileLink && hasOggAudioExtension
    }
    
    /// Converts incompatible file links to compatible file links. Currently only translates ogg/oga links to mp3 links.
    public var byMakingAudioFileCompatibilityAdjustments: URL {
        assert(isWikimediaHostedAudioFileLink)
        
        var mutableComponents = pathComponents.filter { $0 != "/" } // exclude forward slashes to prevent double-slashes when rebuilding the path
        
        guard
            let filename = mutableComponents.last,
            let indexOfTranscoded = mutableComponents.firstIndex(of: "commons")?.advanced(by: 1) ?? mutableComponents.firstIndex(of: "wikipedia")?.advanced(by: 2), // + 2 for wikipedia links to put "transcoded" after the language path component
            indexOfTranscoded < mutableComponents.count
        else {
            return self
        }
        
        mutableComponents.insert("transcoded", at: indexOfTranscoded)
    
        let mp3Filename = filename.appending(".mp3")
        mutableComponents.append(mp3Filename)

        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let path = "/" + mutableComponents.joined(separator: "/")
        urlComponents?.percentEncodedPath = path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) ?? path
        return urlComponents?.wmf_URLWithLanguageVariantCode(wmf_languageVariantCode) ?? self
    }
}



@objc extension NSURL {
    /// deprecated - use namespace methods
    @objc var wmf_isWikiResource: Bool {
        return (self as URL).wikiResourcePath != nil
    }
}
