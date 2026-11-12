import Foundation

struct MetricsEditedPageViewsAPIResponse: Codable {
    struct Item: Codable {
        let timestampString: String
        let viewCount: Int

        enum CodingKeys: String, CodingKey {
            case timestampString = "timestamp"
            case viewCount = "view_count"
        }
    }
    let items: [Item]
}
