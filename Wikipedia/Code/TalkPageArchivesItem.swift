import WMFComponents

struct TalkPageArchivesItem: Equatable, Identifiable, CustomStringConvertible {
    
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
    
    // MARK: Identifiable
    
    typealias ID = Int
    
    var id: Int {
        return pageID
    }
    
    // MARK: Equatable
    
    static func ==(lhs: TalkPageArchivesItem, rhs: TalkPageArchivesItem) -> Bool {
        return lhs.pageID == rhs.pageID
    }
    
    // MARK: CustomStringConvertible
    
    var description: String {
        return displayTitle.removingHTML
    }
}
