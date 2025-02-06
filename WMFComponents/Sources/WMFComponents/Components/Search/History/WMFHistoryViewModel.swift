import Foundation

public final class WMFHistoryViewModel: ObservableObject {
    
    public final class Section: Identifiable {
        let dateWithoutTime: Date
        @Published var items: [Item]
        
        public init(dateWithoutTime: Date, items: [WMFHistoryViewModel.Item]) {
            self.dateWithoutTime = dateWithoutTime
            self.items = items
        }
    }
    
    public final class Item: Identifiable, Equatable {
        public let id: String
        let titleHtml: String
        let description: String?
        let imageURL: URL?
        
        public init(id: String, titleHtml: String, description: String? = nil, imageURL: URL? = nil) {
            self.id = id
            self.titleHtml = titleHtml
            self.description = description
            self.imageURL = imageURL
        }
        
        public static func == (lhs: WMFHistoryViewModel.Item, rhs: WMFHistoryViewModel.Item) -> Bool {
            return lhs.id == rhs.id
        }
    }

    // Closures that call back to the Core Data methods
    // Eventually we want to call a WMFData data controller instead.
    private let deleteAllHistoryAction: () -> Void
    private let deleteHistoryItemAction: (Item) -> Void
    
    @Published var sections: [Section] = []
    @Published public var topPadding: CGFloat = 0
    
    public init(sections: [WMFHistoryViewModel.Section], deleteAllHistoryAction: @escaping () -> Void, deleteHistoryItemAction: @escaping (WMFHistoryViewModel.Item) -> Void) {
        self.sections = sections
        self.deleteAllHistoryAction = deleteAllHistoryAction
        self.deleteHistoryItemAction = deleteHistoryItemAction
    }
    
    func deleteAll() {
        
        // Note: I am assuming this will succeed app-side. Should we pass back a success / fail flag in this action?
        deleteAllHistoryAction()
        self.sections = []
    }
    
    func delete(section: Section, item: Item) {
        
        // Assuming we won't have multiple items in the same section
        guard let itemIndex = section.items.firstIndex(of: item) else {
            return
        }
        
        // Note: I am assuming this will succeed app-side. Should we pass back a success / fail flag in this action?
        deleteHistoryItemAction(item)
        section.items.remove(at: itemIndex)
        sections.removeAll(where: { $0.items.isEmpty })
    }
}
