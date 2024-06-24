import Foundation

internal struct WikipediaSiteInfoLookup: Codable {
    internal struct NamespaceInfo: Codable {
        let namespace: [String: PageNamespace]
        let mainpage: String
    }
    
    let namespaceInfo: NamespaceInfo
    let magicWordInfo: [MagicWord]
}
