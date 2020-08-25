import Foundation

internal struct WikipediaSiteInfoLookup: Codable {
    let namespace: Dictionary<String, PageNamespace>
    let mainpage: String
}
