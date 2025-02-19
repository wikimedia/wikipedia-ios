import SwiftUI
import WMFData

public final class WMFHistoryViewModel: ObservableObject {

    public struct LocalizedStrings {
        let title: String

        public init(title: String) {
            self.title = title
        }
    }

    @Published var sections: [HistorySection] = []
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
    }

    func deleteAll() {
        DispatchQueue.main.async {
            self.sections.removeAll()
        }
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
    }
}
