import Foundation

internal struct WKGrowthTaskAPIResponse: Codable {

    let batchcomplete: Bool
    let `continue`: ContinueData
    let growthtasks: GrowthTasks
    let query: Query

    public struct QualityGateConfig: Codable {
        let imageRecommendation: ImageRecommendation
        let sectionImageRecomendation : SectionImageRecommendation

        enum CodingKeys: String, CodingKey {
            case imageRecommendation = "image-recommendation"
            case sectionImageRecomendation = "section-image-recommendation"
        }
    }

    struct ImageRecommendation: Codable {
        let dailyLimit: Bool
        let dailyCount: Int
    }

    struct SectionImageRecommendation: Codable {
        let dailyLimit: Bool
        let dailyCount: Int
    }

    struct Query: Codable {
        let pages: [Page]
    }

    struct Page: Codable {
        let pageid: Int
        let ns: Int
        let title: String
        let tasktype: String
        let difficulty: String
        let order: Int
        let qualityGateIds: [String]
        let qualityGateConfig: QualityGateConfig
        let token: String
    }

    struct GrowthTasks: Codable {
        let totalCount: Int
        let qualityGateConfig: QualityGateConfig
    }

    struct ContinueData: Codable {
        let ggtoffset: Int
        let continueValue: String

        enum CodingKeys: String, CodingKey {
            case ggtoffset
            case continueValue = "continue"
        }
    }
}
