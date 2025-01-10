import Foundation

public struct WMFWatchlist {
    
    public struct Item {
        public let title: String
        public let revisionID: UInt
        public let oldRevisionID: UInt
        public let username: String
        public let isAnon: Bool
        public let isBot: Bool
        public let timestamp: Date
        public let commentWikitext: String
        public let commentHtml: String
        public let byteLength: UInt
        public let oldByteLength: UInt
        public let project: WMFProject
    }
    
    public let items: [Item]
    public let activeFilterCount: Int
}
