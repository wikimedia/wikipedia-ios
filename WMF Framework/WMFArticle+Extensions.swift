import Foundation

extension WMFArticle {
    @objc public var displayTitleHTML: String {
        set {
            displayTitleHTMLString = newValue
            displayTitle = (newValue as NSString).wmf_stringByRemovingHTML()
        }
        get {
            return displayTitleHTMLString ?? displayTitle ?? url?.wmf_title ?? ""
        }
    }
    
    @objc public var capitalizedWikidataDescriptionOrSnippet: String? {
        guard let wikidataDescription = capitalizedWikidataDescription, wikidataDescription.count > 0 else {
            return snippet
        }
        return wikidataDescription
    }
    
    public var hasChangedValuesForCurrentEventThatAffectPreviews: Bool {
        let previewKeys: Set<String> = ["wikidataDescription", "snippet", "imageURLString"]
        return hasChangedValuesForCurrentEventForKeys(previewKeys)
    }
}
