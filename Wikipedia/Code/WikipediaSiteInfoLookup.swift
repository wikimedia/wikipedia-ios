import Foundation

public struct WikipediaSiteInfoLookup: Codable {
    public struct NamespaceInfo: Codable {
        public let namespace: [String: PageNamespace]
        let mainpage: String
    }
    
    let namespaceInfo: NamespaceInfo
    let magicWordInfo: [MagicWord]
}
