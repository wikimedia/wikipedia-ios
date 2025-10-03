import UIKit

public final class WMFArticlePreviewViewModel {

    public let url: URL?
    public let titleHtml: String
    public let description: String?
    public let imageURL: URL?
    public let image: UIImage?
    public let backgroundImage: UIImage?
    public let snippet: String?

    public init(url: URL?, titleHtml: String, description: String?, imageURLString: String?, isSaved: Bool, snippet: String?) {
        self.url = url
        self.titleHtml = titleHtml
        self.description = description
        
        if let imageURLString {
            self.imageURL = URL(string: imageURLString)
        } else {
            self.imageURL = nil
        }
        self.image = nil
        self.backgroundImage = nil
        self.snippet = snippet
    }

    public init(url: URL?, titleHtml: String, description: String?, imageURL: URL?, isSaved: Bool, snippet: String?) {
        self.url = url
        self.titleHtml = titleHtml
        self.description = description
        self.imageURL = imageURL
        self.image = nil
        self.backgroundImage = nil
        self.snippet = snippet
    }

    public init(url: URL?, titleHtml: String, description: String?, image: UIImage?, backgroundImage: UIImage?, isSaved: Bool, snippet: String?) {
        self.url = url
        self.titleHtml = titleHtml
        self.description = description
        self.imageURL = nil
        self.image = image
        self.backgroundImage = backgroundImage
        self.snippet = snippet
    }

}
