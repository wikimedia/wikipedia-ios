import Foundation

/// A WMFArticle representation
public struct HistoryRecord {
    public let id: String
    public let titleHtml: String
    public let description: String?
    public let imageURL: URL?
    public let viewedDate: Date

    public init(id: String, titleHtml: String, description: String? = nil, imageURL: URL? = nil, viewedDate: Date) {
        self.id = id
        self.titleHtml = titleHtml
        self.description = description
        self.imageURL = imageURL
        self.viewedDate = viewedDate
    }
}

public final class WMFHistoryDataController {

    // MARK: - Dependency Injection Closures

    /// Closure that returns an array of history records
    public typealias RecordsProvider = () -> [HistoryRecord]

    /// Closure that deletes a single history record identified by its id
    public typealias DeleteRecordAction = (String) -> Void

    /// Closure that deletes all history records.
    public typealias DeleteAllRecordsAction = () -> Void

    private let recordsProvider: RecordsProvider
    private let deleteRecordAction: DeleteRecordAction
    private let deleteAllRecordsAction: DeleteAllRecordsAction

    /// Initializes the history data controller.
    /// - Parameters:
    ///   - recordsProvider: A closure returning an array of `HistoryRecord`.
    ///   - deleteRecordAction: A closure that deletes a record (by id).
    ///   - deleteAllRecordsAction: A closure that deletes all history records.
    public init(recordsProvider: @escaping RecordsProvider,
                deleteRecordAction: @escaping DeleteRecordAction,
                deleteAllRecordsAction: @escaping DeleteAllRecordsAction) {
        self.recordsProvider = recordsProvider
        self.deleteRecordAction = deleteRecordAction
        self.deleteAllRecordsAction = deleteAllRecordsAction
    }

    // MARK: - History Models
    /// A simple representation of a history item for UI consumption.
    public struct HistoryItem {
        public let id: String
        public let titleHtml: String
        public let description: String?
        public let imageURL: URL?

        public init(id: String, titleHtml: String, description: String? = nil, imageURL: URL? = nil) {
            self.id = id
            self.titleHtml = titleHtml
            self.description = description
            self.imageURL = imageURL
        }
    }

    /// A simple model representing a section of history items grouped by day.
    public struct HistorySection {
        public let dateWithoutTime: Date
        public let items: [HistoryItem]

        public init(dateWithoutTime: Date, items: [HistoryItem]) {
            self.dateWithoutTime = dateWithoutTime
            self.items = items
        }
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
                HistoryItem(id: record.id,
                            titleHtml: record.titleHtml,
                            description: record.description,
                            imageURL: record.imageURL)
            }
            return HistorySection(dateWithoutTime: day, items: items)
        }

        return sections.sorted(by: { $0.dateWithoutTime > $1.dateWithoutTime })
    }

    /// Deletes a single history record by its identifier.
    /// - Parameter id: The identifier of the record to be deleted
    public func deleteHistoryItem(withID id: String) {
        deleteRecordAction(id)
    }

    /// Deletes all history records.
    public func deleteAllHistory() {
        deleteAllRecordsAction()
    }
}
