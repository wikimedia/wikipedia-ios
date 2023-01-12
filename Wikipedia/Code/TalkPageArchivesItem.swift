import Foundation

struct TalkPageArchivesItem {
    let pageID: Int
    let title: String
    let displayTitle: String

    init?(pageID: Int?, title: String?, displayTitle: String?) {
        guard let pageID = pageID,
              let title = title,
              let displayTitle = displayTitle else {
            return nil
        }

        self.pageID = pageID
        self.title = title
        self.displayTitle = displayTitle
    }
}
