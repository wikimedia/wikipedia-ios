import Foundation

public struct WKImageRecommendation {
    
    let page: Page

    public struct Page {
        public let pageid: Int
        public let title: String
        let growthimagesuggestiondata: [GrowthImageSuggestionData]?
    }

    public struct GrowthImageSuggestionData {
        let titleNamespace: Int
        let titleText: String
        let images: [ImageSuggestion]
    }

    public struct ImageSuggestion: Codable {
        let image: String
        let displayFilename: String
        let source: String
        let projects: [String]
        let metadata: ImageMetadata
    }

    public struct ImageMetadata: Codable {
        let descriptionUrl: String
        let thumbUrl: String
        let fullUrl: String
        let originalWidth: Int
        let originalHeight: Int
        let mediaType: String
        let description: String?
        let author: String?
        let license: String
        let date: String
        let caption: String?
        let categories: [String]
        let reason: String
        let contentLanguageName: String
    }

}
