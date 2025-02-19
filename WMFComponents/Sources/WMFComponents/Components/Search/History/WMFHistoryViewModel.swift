import SwiftUI
import WMFData

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

    public struct LocalizedStrings {
        let title: String

        public init(title: String) {
            self.title = title
        }
    }

    @Published var sections: [Section] = []
    @Published public var topPadding: CGFloat = 0

    private let historyDataController: WMFHistoryDataController
    let localizedStrings: LocalizedStrings

    public init(localizedStrings: WMFHistoryViewModel.LocalizedStrings, historyDataController: WMFHistoryDataController, topPadding: CGFloat = 0) {
        self.localizedStrings = localizedStrings
        self.historyDataController = historyDataController
        self.topPadding = topPadding
        loadHistory()
    }

    public func loadHistory() {
        let dataSections = historyDataController.fetchHistorySections()
        let viewModelSections = dataSections.map { dataSection -> Section in
            let items = dataSection.items.map { dataItem in
                Item(id: dataItem.id,
                     titleHtml: dataItem.titleHtml,
                     description: dataItem.description,
                     imageURL: dataItem.imageURL)
            }
            return Section(dateWithoutTime: dataSection.dateWithoutTime, items: items)
        }

        DispatchQueue.main.async {
            self.sections = viewModelSections
        }
    }

    func deleteAll() {

        historyDataController.deleteAllHistory()
        DispatchQueue.main.async {
            self.sections.removeAll()
        }
    }

    public func delete(section: Section, item: Item) {
        guard let itemIndex = section.items.firstIndex(of: item) else {
            return
        }
        historyDataController.deleteHistoryItem(withID: item.id)
        section.items.remove(at: itemIndex)

        if section.items.isEmpty {
            DispatchQueue.main.async {
                self.sections.removeAll(where: { $0.dateWithoutTime == section.dateWithoutTime })
            }
        }
    }
}
