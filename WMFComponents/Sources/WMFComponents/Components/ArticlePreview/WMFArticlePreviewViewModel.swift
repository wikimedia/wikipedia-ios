import UIKit

public final class WMFArticlePreviewViewModel {

    public let url: URL?
    public let titleHtml: String
    public let description: String?
    public let imageURL: URL?
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
        
        self.snippet = snippet
    }

}
