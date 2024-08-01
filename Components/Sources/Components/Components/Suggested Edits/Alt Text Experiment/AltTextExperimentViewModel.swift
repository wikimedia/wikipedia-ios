import Foundation

public struct AltTextExperimentViewModel {
    
    public struct LocalizedStrings {
        public let articleNavigationBarTitle: String
        
        public init(articleNavigationBarTitle: String) {
            self.articleNavigationBarTitle = articleNavigationBarTitle
        }
    }
    
    public let localizedStrings: LocalizedStrings
    public let articleTitle: String
    public let caption: String?
    public let imageFullURL: String
    public let imageThumbURL: String
    public let filename: String
    public let imageWikitext: String
    public let fullArticleWikitextWithImage: String
    public let lastRevisionID: UInt64

    public init(localizedStrings: LocalizedStrings, articleTitle: String, caption: String?, imageFullURL: String, imageThumbURL: String, filename: String, imageWikitext: String, fullArticleWikitextWithImage: String, lastRevisionID: UInt64) {
        self.localizedStrings = localizedStrings
        self.articleTitle = articleTitle
        self.caption = caption
        self.imageFullURL = imageFullURL
        self.imageThumbURL = imageThumbURL
        self.filename = filename
        self.imageWikitext = imageWikitext
        self.fullArticleWikitextWithImage = fullArticleWikitextWithImage
        self.lastRevisionID = lastRevisionID
    }
}

