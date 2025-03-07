import Foundation

/// A WMFArticle representation
public struct HistoryRecord {
    public let id: Int
    public let title: String
    public let descriptionOrSnippet: String?
    public let shortDescription: String?
    public let articleURL: URL?
    public let imageURL: String?
    public let viewedDate: Date
    public let isSaved: Bool
    public let snippet: String?

    public init(id: Int, title: String, descriptionOrSnippet: String?, shortDescription: String?, articleURL: URL?, imageURL: String?, viewedDate: Date, isSaved: Bool, snippet: String?) {
        self.id = id
        self.title = title
        self.descriptionOrSnippet = descriptionOrSnippet
        self.shortDescription = shortDescription
        self.articleURL = articleURL
        self.imageURL = imageURL
        self.viewedDate = viewedDate
        self.isSaved = isSaved
        self.snippet = snippet
    }
}

public final class WMFHistoryDataController {

    // MARK: - Dependency Injection Closures

    /// Closure that returns an array of history records
    public typealias RecordsProvider = () -> [HistoryRecord]

    /// Closure that deletes a single history record
    public typealias DeleteRecordAction = (HistoryItem) -> Void

    ///
    public typealias SaveRecordAction = (HistoryItem) -> Void

    ///
    public typealias UnsaveRecordAction = (HistoryItem) -> Void

    private let recordsProvider: RecordsProvider
    private let deleteRecordAction: DeleteRecordAction
    private let saveRecordAction: SaveRecordAction
    private let unsaveRecordAction: UnsaveRecordAction

    /// Initializes the history data controller.
    /// - Parameters:
    ///   - recordsProvider: A closure returning an array of `HistoryRecord`.
    ///   - deleteRecordAction: A closure that deletes a record (by id).
    ///   - deleteAllRecordsAction: A closure that deletes all history records.
    public init(recordsProvider: @escaping RecordsProvider, deleteRecordAction: @escaping DeleteRecordAction, saveArticleAction: @escaping SaveRecordAction, unsaveArticleAction: @escaping UnsaveRecordAction) {
        self.recordsProvider = recordsProvider
        self.deleteRecordAction = deleteRecordAction
        self.saveRecordAction = saveArticleAction
        self.unsaveRecordAction = unsaveArticleAction
    }

    private func getURL(_ string: String?) -> URL? {
        guard let string else { return nil }
        return URL(string: string)
    }

    // MARK: - Data Access Methods

    /// Groups history records by day (using the start of the day) and returns an array of `HistorySection`.
    public func fetchHistorySections() -> [HistorySection] {
        let records = recordsProvider()
        let calendar = Calendar.current

        let groupedRecords = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.viewedDate)
        }

        let sections: [HistorySection] = groupedRecords.map { (day, records) in
            let items = records.map { record in
                HistoryItem(id: String(record.id),
                            url: record.articleURL,
                            titleHtml: record.title,
                            snippetOrDescription: record.descriptionOrSnippet,
                            shortDescription: record.shortDescription,
                            imageURL: getURL(record.imageURL),
                            isSaved: record.isSaved,
                            snippet: record.snippet
                )
            }
            return HistorySection(dateWithoutTime: day, items: items)
        }

        return sections.sorted(by: { $0.dateWithoutTime > $1.dateWithoutTime })
    }

    public func deleteHistoryItem(_ item: HistoryItem) {
        deleteRecordAction(item)
    }

    public func saveHistoryItem(_ item: HistoryItem) {
        saveRecordAction(item)
    }

    public func unsaveHistoryItem(_ item: HistoryItem) {
        unsaveRecordAction(item)
    }

}

public final class HistorySection: Identifiable {
    public let dateWithoutTime: Date
    @Published public var items: [HistoryItem]

    public init(dateWithoutTime: Date, items: [HistoryItem]) {
        self.dateWithoutTime = dateWithoutTime
        self.items = items
    }
}

public final class HistoryItem: Identifiable, Equatable {
    public let id: String
    public let url: URL?
    public let titleHtml: String
    public let description: String?
    public let shortDescription: String?
    public let imageURL: URL?
    public let isSaved: Bool
    public let snippet: String?

    public init(id: String, url: URL?, titleHtml: String, snippetOrDescription: String?, shortDescription: String?, imageURL: URL?, isSaved: Bool, snippet: String?) {
        self.id = id
        self.url = url
        self.titleHtml = titleHtml
        self.description = snippetOrDescription
        self.shortDescription = shortDescription
        self.imageURL = imageURL
        self.isSaved = isSaved
        self.snippet = snippet
    }

    public static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return lhs.id == rhs.id
    }
}
