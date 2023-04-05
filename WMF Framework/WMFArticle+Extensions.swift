import Foundation

extension WMFArticle {
    @objc public var capitalizedWikidataDescriptionOrSnippet: String? {
        guard let wikidataDescription = capitalizedWikidataDescription, !wikidataDescription.isEmpty else {
            return snippet
        }
        return wikidataDescription
    }
    
    public var hasChangedValuesForCurrentEventThatAffectPreviews: Bool {
        let previewKeys: Set<String> = ["wikidataDescription", "snippet", "imageURLString"]
        return hasChangedValuesForCurrentEventForKeys(previewKeys)
    }
    
    @objc public var hasChangedValuesForCurrentEventThatAffectSavedArticlesFetch: Bool {
        let previewKeys: Set<String> = ["savedDate", "isDownloaded"]
        return hasChangedValuesForCurrentEventForKeys(previewKeys)
    }

    @objc public var hasChangedValuesForCurrentEventThatAffectSavedState: Bool {
        let previewKeys: Set<String> = ["savedDate"]
        return hasChangedValuesForCurrentEventForKeys(previewKeys)
    }
    
    public var hasChangedValuesForCurrentEventThatAffectSavedArticlePreviews: Bool {
        let previewKeys: Set<String> = ["wikidataDescription", "snippet", "imageURLString", "isDownloaded", "readingLists", "errorCodeNumber"]
        return hasChangedValuesForCurrentEventForKeys(previewKeys)
    }
    
    public var namespace: PageNamespace? {
        return url?.namespace
    }
    
    public var namespaceAndTitle: (namespace: PageNamespace, title: String)? {
        return url?.namespaceAndTitle
    }
    
    @objc public var namespaceNumber: NSNumber? {
        guard let namespace = namespace else {
            return nil
        }
        return NSNumber(integerLiteral: namespace.rawValue)
    }
    
    public var isSaved: Bool {
        get {
            return savedDate != nil
        }
        set {
            savedDate = newValue ? Date() : nil
        }
    }
    
    @objc public func feedArticlePreview() -> WMFFeedArticlePreview? {
        
        var dictionary: [AnyHashable: Any] = [
            "displayTitle": displayTitle as Any,
            "displayTitleHTML": displayTitleHTML,
            "thumbnailURL": thumbnailURL as Any,
            "imageURLString": imageURLString as Any,
            "wikidataDescription": wikidataDescription as Any,
            "snippet": snippet as Any,
            "imageWidth": imageWidth as Any,
            "imageHeight": imageHeight as Any
        ]
        
        if let articleURLString = key?.decomposedStringWithCanonicalMapping {
            dictionary["articleURL"] = URL(string: articleURLString)
        }
        
        return try? WMFFeedArticlePreview(dictionary: dictionary)
    }
}
