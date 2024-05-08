import Foundation

internal struct WikipediaSiteInfoLookup: Codable {
    internal struct Namespace: Codable {
        let namespace: [String: PageNamespace]
        let mainpage: String
    }
    
    let namespace: Namespace
    let magicWords: [MagicWord]
}
