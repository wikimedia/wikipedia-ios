import Foundation


public class PageHistorySection: NSObject {
    public let sectionTitle: String
    public let items: [WMFPageHistoryRevision]
    
    public init(sectionTitle: String, items: [WMFPageHistoryRevision]) {
        self.sectionTitle = sectionTitle
        self.items = items
    }
}