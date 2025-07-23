import UIKit

public final class WMFArticlePreviewViewModel {

    public let url: URL?
    public let titleHtml: String
    public let description: String?
    public let imageURL: URL?
    public let snippet: String?

    public init(url: URL?, titleHtml: String, description: String?, imageURL: URL?, isSaved: Bool, snippet: String?) {
        self.url = url
        self.titleHtml = titleHtml
        self.description = description
        self.imageURL = imageURL
        self.snippet = snippet
    }

}
