import SwiftUI
import WMFData
import Combine

public final class WMFHistoryViewModel: ObservableObject {

    // MARK: Nested Types

    public struct LocalizedStrings {
        let title: String
        let emptyViewTitle: String
        let emptyViewSubtitle: String
        let todayTitle: String
        let yesterdayTitle: String
        let readNowActionTitle: String
        let saveForLaterActionTitle: String
        let unsaveActionTitle: String
        let shareActionTitle: String
        let deleteSwipeActionLabel: String

        public init(title: String, emptyViewTitle: String, emptyViewSubtitle: String, todayTitle: String, yesterdayTitle: String, readNowActionTitle: String, saveForLaterActionTitle: String, unsaveActionTitle: String, shareActionTitle: String, deleteSwipeActionLabel: String) {
            self.title = title
            self.emptyViewTitle = emptyViewTitle
            self.emptyViewSubtitle = emptyViewSubtitle
            self.todayTitle = todayTitle
            self.yesterdayTitle = yesterdayTitle
            self.readNowActionTitle = readNowActionTitle
            self.saveForLaterActionTitle = saveForLaterActionTitle
            self.unsaveActionTitle = unsaveActionTitle
            self.shareActionTitle = shareActionTitle
            self.deleteSwipeActionLabel = deleteSwipeActionLabel
        }
    }

    // MARK: Types

    public typealias ShareRecordAction = (CGRect?, HistoryItem) -> Void
    public typealias OnRecordTapAction = ((HistoryItem) -> Void)?

    @Published public var sections: [HistorySection] = [] {
        didSet {
            isEmpty = sections.isEmpty
        }
    }

    // MARK: Properties

    @Published public var topPadding: CGFloat = 0
    @Published public var isEmpty: Bool = true
    @Published var geometryFrames: [String: CGRect] = [:]

    internal let localizedStrings: LocalizedStrings
    internal let emptyViewImage: UIImage?
    private let historyDataController: WMFHistoryDataController
    private var onTapArticle: OnRecordTapAction
    private let shareRecordAction: ShareRecordAction

    // MARK: Lifecycle

    public init(emptyViewImage: UIImage?, localizedStrings: WMFHistoryViewModel.LocalizedStrings, historyDataController: WMFHistoryDataController, topPadding: CGFloat = 0, onTapRecord: OnRecordTapAction, shareRecordAction: @escaping ShareRecordAction) {
        self.emptyViewImage = emptyViewImage
        self.localizedStrings = localizedStrings
        self.historyDataController = historyDataController
        self.topPadding = topPadding
        self.onTapArticle = onTapRecord
        self.shareRecordAction = shareRecordAction

        loadHistory()
    }

    // MARK: Public functions

    public func loadHistory() {
        let dataSections = historyDataController.fetchHistorySections()
        let viewModelSections = dataSections.map { dataSection -> HistorySection in
            let items = dataSection.items.map { dataItem in
                HistoryItem(id: dataItem.id,
                            url: dataItem.url,
                            titleHtml: dataItem.titleHtml,
                            description: dataItem.description,
                            shortDescription: dataItem.shortDescription,
                            imageURL: dataItem.imageURL,
                            isSaved: dataItem.isSaved,
                            snippet: dataItem.snippet,
                            variant: dataItem.variant)
            }
            return HistorySection(dateWithoutTime: dataSection.dateWithoutTime, items: items)
        }

        DispatchQueue.main.async {
            self.sections = viewModelSections
        }
        isEmpty = dataSections.isEmpty || dataSections.allSatisfy { $0.items.isEmpty }
    }

    // MARK: Internal functions

    func delete(section: HistorySection, item: HistoryItem) {
        guard let itemIndex = section.items.firstIndex(of: item) else {
            return
        }

        section.items.remove(at: itemIndex)
        if section.items.isEmpty {
            DispatchQueue.main.async {
                self.sections.removeAll(where: { $0.dateWithoutTime == section.dateWithoutTime })
            }
        }
        historyDataController.deleteHistoryItem(item)

        isEmpty = sections.isEmpty || sections.allSatisfy { $0.items.isEmpty }

    }

    func saveOrUnsave(item: HistoryItem) {
        if item.isSaved {
            historyDataController.unsaveHistoryItem(item)
        } else {
            historyDataController.saveHistoryItem(item)
        }
    }

    func share(frame: CGRect?, item: HistoryItem) {
        shareRecordAction(frame, item)
    }

    func onTap(_ item: HistoryItem) {
        onTapArticle?(item)
    }

    internal func headerTextForSection(_ section: HistorySection) -> String {
        let date = section.dateWithoutTime
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return localizedStrings.todayTitle
        } else if calendar.isDateInYesterday(date) {
            return localizedStrings.yesterdayTitle
        } else {
            return DateFormatter.wmfFullDateFormatter.string(from: date)
        }
    }
}
