import Foundation

public struct WMFGrowthTask {

    public let pages: [Page]

    public struct Page {
        public let pageid: Int
        public let title: String
        let tasktype: String
        let difficulty: String
    }

}
