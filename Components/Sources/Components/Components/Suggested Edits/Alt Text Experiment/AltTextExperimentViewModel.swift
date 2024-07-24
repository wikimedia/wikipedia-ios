import Foundation

public struct AltTextExperimentViewModel {
    public let articleTitle: String
    public let caption: String?
    public let imageFullURL: String
    public let imageThumbURL: String
    public let filename: String

    public init(articleTitle: String, caption: String?, imageFullURL: String, imageThumbURL: String, filename: String) {
        self.articleTitle = articleTitle
        self.caption = caption
        self.imageFullURL = imageFullURL
        self.imageThumbURL = imageThumbURL
        self.filename = filename
    }
}

