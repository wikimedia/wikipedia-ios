import Foundation

open class PageHistorySection: NSObject {
    @objc public let sectionTitle: String
    @objc public let items: [WMFPageHistoryRevision]
    
    @objc public init(sectionTitle: String, items: [WMFPageHistoryRevision]) {
        self.sectionTitle = sectionTitle
        self.items = items
    }
}
