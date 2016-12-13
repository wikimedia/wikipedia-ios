import Foundation


open class PageHistorySection: NSObject {
    open let sectionTitle: String
    open let items: [WMFPageHistoryRevision]
    
    public init(sectionTitle: String, items: [WMFPageHistoryRevision]) {
        self.sectionTitle = sectionTitle
        self.items = items
    }
}
