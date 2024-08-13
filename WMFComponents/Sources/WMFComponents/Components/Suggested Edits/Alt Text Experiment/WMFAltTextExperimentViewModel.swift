import Foundation

public struct WMFAltTextExperimentViewModel {
    
    public struct LocalizedStrings {
        public let articleNavigationBarTitle: String
        public let editSummary: String
        
        public init(articleNavigationBarTitle: String, editSummary: String) {
            self.articleNavigationBarTitle = articleNavigationBarTitle
            self.editSummary = editSummary
        }
    }
    
    public let localizedStrings: LocalizedStrings
    public let articleTitle: String
    public let caption: String?
    public let imageFullURL: String?
    public let imageThumbURL: String?
    public let filename: String
    public let imageWikitext: String
    public let fullArticleWikitextWithImage: String
    public let lastRevisionID: UInt64
    public let sectionID: Int?
    public let isFlowB: Bool

    public init(localizedStrings: LocalizedStrings, articleTitle: String, caption: String?, imageFullURL: String?, imageThumbURL: String?, filename: String, imageWikitext: String, fullArticleWikitextWithImage: String, lastRevisionID: UInt64, sectionID: Int?, isFlowB: Bool) {
        self.localizedStrings = localizedStrings
        self.articleTitle = articleTitle
        self.caption = caption
        self.imageFullURL = imageFullURL
        self.imageThumbURL = imageThumbURL
        self.filename = filename
        self.imageWikitext = imageWikitext
        self.fullArticleWikitextWithImage = fullArticleWikitextWithImage
        self.lastRevisionID = lastRevisionID
        self.sectionID = sectionID
        self.isFlowB = isFlowB
    }
}

