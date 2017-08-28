import Foundation

open class PageHistorySection: NSObject {
    @objc open let sectionTitle: String
    @objc open let items: [WMFPageHistoryRevision]
    
    @objc public init(sectionTitle: String, items: [WMFPageHistoryRevision]) {
        self.sectionTitle = sectionTitle
        self.items = items
    }
}
