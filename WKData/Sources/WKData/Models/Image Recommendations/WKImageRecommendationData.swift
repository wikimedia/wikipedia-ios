import Foundation

public struct WKImageRecommendationData {
    public let pageId: Int
    public let pageTitle: String
    public let image: String
    public let filename: String
    public let thumbUrl: String
    public let fullUrl: String
    public let description: String?

    public init(pageId: Int, pageTitle: String, image: String, filename: String, thumbUrl: String, fullUrl: String, description: String?) {
        self.pageId = pageId
        self.pageTitle = pageTitle
        self.image = image
        self.filename = filename
        self.thumbUrl = thumbUrl
        self.fullUrl = fullUrl
        self.description = description
    }
}
