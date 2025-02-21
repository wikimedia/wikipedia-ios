import SwiftUI
import WMFData
import Combine

public final class WMFHistoryViewModel: ObservableObject {

    public struct LocalizedStrings {
        let title: String
        let emptyViewTitle: String
        let emptyViewSubtitle: String

        public init(title: String, emptyViewTitle: String, emptyViewSubtitle: String) {
            self.title = title
            self.emptyViewTitle = emptyViewTitle
            self.emptyViewSubtitle = emptyViewSubtitle
        }
    }

    @Published var sections: [HistorySection] = []
    @Published public var topPadding: CGFloat = 0

    private let historyDataController: WMFHistoryDataController
    internal let localizedStrings: LocalizedStrings

    public var isEmpty: Bool = true

    public init(localizedStrings: WMFHistoryViewModel.LocalizedStrings, historyDataController: WMFHistoryDataController, topPadding: CGFloat = 0) {
        self.localizedStrings = localizedStrings
        self.historyDataController = historyDataController
        self.topPadding = topPadding
        loadHistory()
    }

    public func loadHistory() {
        let dataSections = historyDataController.fetchHistorySections()
        let viewModelSections = dataSections.map { dataSection -> HistorySection in
            let items = dataSection.items.map { dataItem in
                HistoryItem(id: dataItem.id,
                            titleHtml: dataItem.titleHtml,
                            description: dataItem.description,
                            imageURL: dataItem.imageURL)
            }
            return HistorySection(dateWithoutTime: dataSection.dateWithoutTime, items: items)
        }

        DispatchQueue.main.async {
            self.sections = viewModelSections
        }
        isEmpty = dataSections.isEmpty || dataSections.allSatisfy { $0.items.isEmpty }
    }

    public func delete(section: HistorySection, item: HistoryItem) {
        guard let itemIndex = section.items.firstIndex(of: item) else {
            return
        }

        section.items.remove(at: itemIndex)
        if section.items.isEmpty {
            DispatchQueue.main.async {
                self.sections.removeAll(where: { $0.dateWithoutTime == section.dateWithoutTime })
            }
        }
        historyDataController.deleteHistoryItem(with: section, item)

        isEmpty = sections.isEmpty || sections.allSatisfy { $0.items.isEmpty }

    }
}
