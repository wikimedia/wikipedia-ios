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
        let previewKeys: Set<String> = ["wikidataDescription", "snippet", "imageURLString", "isDownloaded", "readingLists"]
        return hasChangedValuesForCurrentEventForKeys(previewKeys)
    }
}
