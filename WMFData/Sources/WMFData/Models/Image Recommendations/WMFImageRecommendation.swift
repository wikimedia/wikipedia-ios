import Foundation

public struct WMFImageRecommendation: Sendable {
    
    let page: Page

    public struct Page: Sendable {
        public let pageid: Int
        public let title: String
        public let growthimagesuggestiondata: [GrowthImageSuggestionData]?
        public let revisions: [Revision]
    }

    public struct Revision: Sendable {
        public let revID: Int
        public let wikitext: String
    }

    public struct GrowthImageSuggestionData: Sendable {
        let titleNamespace: Int
        public let titleText: String
        public let images: [ImageSuggestion]
    }

    public struct ImageSuggestion: Codable, Sendable {
        public let image: String
        public let displayFilename: String
        public let source: String
        let projects: [String]
        public let metadata: ImageMetadata
    }

    public struct ImageMetadata: Codable, Sendable {
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
        public let reason: String
        let contentLanguageName: String
        let sectionNumber: String?
    }

}
