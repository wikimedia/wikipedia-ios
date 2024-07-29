import Foundation

public struct AltTextExperimentViewModel {
    public let articleTitle: String
    public let caption: String?
    public let imageFullURL: String
    public let imageThumbURL: String
    public let filename: String
    public let imageWikitext: String
    public let fullArticleWikitextWithImage: String
    public let lastRevisionID: UInt64

    public init(articleTitle: String, caption: String?, imageFullURL: String, imageThumbURL: String, filename: String, imageWikitext: String, fullArticleWikitextWithImage: String, lastRevisionID: UInt64) {
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

