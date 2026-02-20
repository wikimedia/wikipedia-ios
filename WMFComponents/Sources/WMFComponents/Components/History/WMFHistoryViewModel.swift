import SwiftUI
import WMFData

public final class WMFHistoryViewModel: ObservableObject {

    // MARK: - Nested Types

    public struct LocalizedStrings {
        let emptyViewTitle: String
        let emptyViewSubtitle: String
        let todayTitle: String
        let yesterdayTitle: String
        let openArticleActionTitle: String
        let saveForLaterActionTitle: String
        let unsaveActionTitle: String
        let shareActionTitle: String
        let deleteSwipeActionLabel: String
        let historyHeaderTitle: String

        public init(emptyViewTitle: String, emptyViewSubtitle: String, todayTitle: String, yesterdayTitle: String, openArticleActionTitle: String, saveForLaterActionTitle: String, unsaveActionTitle: String, shareActionTitle: String, deleteSwipeActionLabel: String, historyHeaderTitle: String) {
            self.emptyViewTitle = emptyViewTitle
            self.emptyViewSubtitle = emptyViewSubtitle
            self.todayTitle = todayTitle
            self.yesterdayTitle = yesterdayTitle
            self.openArticleActionTitle = openArticleActionTitle
            self.saveForLaterActionTitle = saveForLaterActionTitle
            self.unsaveActionTitle = unsaveActionTitle
            self.shareActionTitle = shareActionTitle
            self.deleteSwipeActionLabel = deleteSwipeActionLabel
            self.historyHeaderTitle = historyHeaderTitle
        }
    }

    // MARK: - Types

    public typealias ShareRecordAction = (CGRect?, HistoryItem) -> Void
    public typealias OnRecordTapAction = ((HistoryItem) -> Void)

    @Published public var sections: [HistorySection] = [] {
        didSet {
            isEmpty = sections.isEmpty
        }
    }

    // MARK: - Properties

    @Published public var topPadding: CGFloat = 0
    @Published public var isEmpty: Bool = true
    var geometryFrames: [String: CGRect] = [:]

    internal let localizedStrings: LocalizedStrings
    internal let emptyViewImage: UIImage?
    private let historyDataController: WMFHistoryDataControllerProtocol
    public var onTapArticle: OnRecordTapAction?
    public var shareRecordAction: ShareRecordAction?
    private let imageDataController = WMFImageDataController()

    // MARK: - Lifecycle

    public init(emptyViewImage: UIImage?, localizedStrings: WMFHistoryViewModel.LocalizedStrings, historyDataController: WMFHistoryDataControllerProtocol, topPadding: CGFloat = 0) {
        self.emptyViewImage = emptyViewImage
        self.localizedStrings = localizedStrings
        self.historyDataController = historyDataController
        self.topPadding = topPadding

        loadHistory()
    }

    // MARK: - Public functions

    public func loadHistory() {
        let dataSections = historyDataController.fetchHistorySections()
        let viewModelSections = dataSections.map { dataSection -> HistorySection in
            let items = dataSection.items.map { dataItem in
                HistoryItem(id: dataItem.id,
                            url: dataItem.url,
                            titleHtml: dataItem.titleHtml,
                            description: dataItem.description,
                            shortDescription: dataItem.shortDescription,
                            imageURLString: dataItem.imageURLString,
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

    // MARK: - Internal functions

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

    public func saveOrUnsave(item: HistoryItem, in section: HistorySection) {

        guard let sectionIndex = sections.firstIndex(of: section),
            let itemIndex    = sections[sectionIndex].items.firstIndex(of: item)
        else {
            return
        }
        let newIsSaved = !sections[sectionIndex].items[itemIndex].isSaved

        // reassign the array to update the view model immediately
        let newSections = sections
        newSections[sectionIndex].items[itemIndex].isSaved = newIsSaved
        sections = newSections

        Task {
            await MainActor.run {
                if newIsSaved {
                    historyDataController.saveHistoryItem(sections[sectionIndex].items[itemIndex])
                } else {
                    historyDataController.unsaveHistoryItem(sections[sectionIndex].items[itemIndex])
                }
            }
        }
    }
    
    func loadImage(imageURLString: String?) async throws -> UIImage? {
        
        guard let imageURLString,
              let url = URL(string: imageURLString) else {
            return nil
        }
        
        let data = try await imageDataController.fetchImageData(url: url)
        return UIImage(data: data)
    }

    func share(frame: CGRect?, item: HistoryItem) {
        shareRecordAction?(frame, item)
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
            return DateFormatter.wmfWeekdayMonthDayDateFormatter.string(from: date)
        }
    }
}
