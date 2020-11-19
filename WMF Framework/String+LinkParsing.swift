/// Detect Wiki namespace in strings. For example, detect that "/wiki/Talk:Dog" is a talk page and "/wiki/Special:ApiSandbox" is a special page
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

/// Page title transformation
public extension String {
    var percentEncodedPageTitleForPathComponents: String? {
        return denormalizedPageTitle?.addingPercentEncoding(withAllowedCharacters: .encodeURIComponentAllowed)
    }

     var normalizedPageTitle: String? {
        return replacingOccurrences(of: "_", with: " ").precomposedStringWithCanonicalMapping
     }
    
     var denormalizedPageTitle: String? {
        return replacingOccurrences(of: " ", with: "_").precomposedStringWithCanonicalMapping
     }
    
    var asTalkPageFragment: String? {
        let denormalizedName = replacingOccurrences(of: " ", with: "_")
        let unlinkedName = denormalizedName.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: "")
        return unlinkedName.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.wmf_encodeURIComponentAllowed())
    }
    
    //assumes string is already normalized
    var googleFormPercentEncodedPageTitle: String? {
        return googleFormPageTitle?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    var googleFormPageTitle: String? {
        return replacingOccurrences(of: " ", with: "+").precomposedStringWithCanonicalMapping
    }
    
    var unescapedNormalizedPageTitle: String? {
        return removingPercentEncoding?.normalizedPageTitle
    }
    
    var isReferenceFragment: Bool {
        return contains("ref_")
    }
    
    var isCitationFragment: Bool {
        return contains("cite_note")
    }
    
    var isEndNoteFragment: Bool {
        return contains("endnote_")
    }
}

@objc extension NSString {
    /// Deprecated - use namespace methods
    @objc var wmf_isWikiResource: Bool {
        return (self as String).wikiResourcePath != nil
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_pathWithoutWikiPrefix: String? {
        return (self as String).wikiResourcePath
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_denormalizedPageTitle: String? {
        return (self as String).denormalizedPageTitle
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_normalizedPageTitle: String? {
        return (self as String).normalizedPageTitle
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_unescapedNormalizedPageTitle: String? {
        return (self as String).unescapedNormalizedPageTitle
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_isReferenceFragment: Bool {
        return (self as String).isReferenceFragment
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_isCitationFragment: Bool {
        return (self as String).isCitationFragment
    }
    
    /// Deprecated - use swift methods
    @objc var wmf_isEndNoteFragment: Bool {
        return (self as String).isEndNoteFragment
    }
}
