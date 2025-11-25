import Foundation

struct MetricsEditCountAPIRResponse: Codable {
    struct Item: Codable {
        let timestampString: String
        let editCount: Int
        
        enum CodingKeys: String, CodingKey {
            case timestampString = "timestamp"
            case editCount = "edit_count"
        }
    }
    let items: [Item]
}
