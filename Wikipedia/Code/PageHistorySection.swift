import Foundation
import WMFData

/// A group of revisions that share one calendar day.
struct PageHistorySection {
    let sectionTitle: String
    let items: [WMFPageRevision]
}
