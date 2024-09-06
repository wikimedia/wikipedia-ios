import Foundation

internal struct WMFImageRecommendationAPIResponse: Codable {

    let batchcomplete: Bool
    let query: Query

    struct Query: Codable {
        let pages: [Page]
    }

    struct Page: Codable {
        let pageid: Int
        let title: String
        let ns: Int
        let growthimagesuggestiondata: [GrowthImageSuggestionData]?
        let revisions: [Revision]
        let pageimage: String?
    }

    struct Revision: Codable {
        let revid: Int
        let parentid: Int
        let minor: Bool
        let user: String
        let timestamp: String
        let comment: String
        let wikitext: Wikitext

        enum CodingKeys: String, CodingKey {
            case revid, parentid, minor, user, timestamp, comment
            case wikitext = "slots"
        }
    }

    struct Wikitext: Codable {
        let main: Content
    }

    struct Content: Codable {
        let contentmodel: String
        let contentformat: String
        let content: String
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
        let description: String?
        let author: String?
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
