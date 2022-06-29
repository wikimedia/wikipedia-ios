import Foundation

internal struct WikipediaSiteInfoLookup: Codable {
    let namespace: [String: PageNamespace]
    let mainpage: String
}
