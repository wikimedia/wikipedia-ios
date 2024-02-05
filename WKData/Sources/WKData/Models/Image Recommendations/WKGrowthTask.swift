import Foundation

public struct WKGrowthTask {

    public let pages: [Page]

    public struct Page {
        let pageid: Int
        let title: String
        let tasktype: String
        let difficulty: String
    }

}
