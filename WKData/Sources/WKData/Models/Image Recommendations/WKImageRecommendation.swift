import Foundation

public struct WKImageRecommendation {
    
    let page: Page

    public struct Page {
        public let pageid: Int
        public let title: String
        public let growthimagesuggestiondata: [GrowthImageSuggestionData]?
    }

    public struct GrowthImageSuggestionData {
        let titleNamespace: Int
        let titleText: String
        public let images: [ImageSuggestion]
    }

    public struct ImageSuggestion: Codable {
        public let image: String
        public let displayFilename: String
        let source: String
        let projects: [String]
        public let metadata: ImageMetadata
    }

    public struct ImageMetadata: Codable {
        public let descriptionUrl: String
        public let thumbUrl: String
        public let fullUrl: String
        let originalWidth: Int
        let originalHeight: Int
        let mediaType: String
        public let description: String?
        let author: String?
        let license: String
        let date: String
        let caption: String?
        let categories: [String]
        let reason: String
        let contentLanguageName: String
    }

}
