import Foundation

internal struct WKImageRecommendationAPIResponse: Codable {

    let batchcomplete: Bool
    let query: Query

    struct Query: Codable {
        let pages: [Page]
    }

    struct Page: Codable {
        let pageid: Int
        let title: String
        let ns: Int
        let growthimagesuggestiondata: [GrowthImageSuggestionData]
    }

    struct GrowthImageSuggestionData: Codable {
        let titleNamespace: Int
        let titleText: String
        let images: [ImageSuggestion]
        let datasetId: String
    }

    struct ImageSuggestion: Codable {
        let image: String
        let displayFilename: String
        let source: String
        let projects: [String]
        let metadata: ImageMetadata
        let sectionNumber: Int?
        let sectionTitle: String?
    }

    struct ImageMetadata: Codable {
        let descriptionUrl: String
        let thumbUrl: String
        let fullUrl: String
        let originalWidth: Int
        let originalHeight: Int
        let mustRender: Bool
        let isVectorized: Bool
        let mediaType: String
        let description: String
        let author: String
        let license: String
        let date: String
        let caption:String?
        let categories: [String]
        let reason: String
        let contentLanguageName: String
        let sectionNumber: String?
        let sectionTitle: String?
    }
}
