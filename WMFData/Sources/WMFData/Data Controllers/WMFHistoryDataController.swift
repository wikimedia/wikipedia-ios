import Foundation

/// A WMFArticle representation
public struct HistoryRecord {
    public let id: Int
    public let title: String
    public let description: String?
    public let imageURL: String?
    public let viewedDate: Date

    public init(id: Int, title: String, description: String? = nil, imageURL: String? = nil, viewedDate: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.viewedDate = viewedDate
    }
}

public final class WMFHistoryDataController {

    // MARK: - Dependency Injection Closures

    /// Closure that returns an array of history records
    public typealias RecordsProvider = () -> [HistoryRecord]

    /// Closure that deletes a single history record 
    public typealias DeleteRecordAction = (HistorySection, HistoryItem) -> Void


    private let recordsProvider: RecordsProvider
    private let deleteRecordAction: DeleteRecordAction

    /// Initializes the history data controller.
    /// - Parameters:
    ///   - recordsProvider: A closure returning an array of `HistoryRecord`.
    ///   - deleteRecordAction: A closure that deletes a record (by id).
    ///   - deleteAllRecordsAction: A closure that deletes all history records.
    public init(recordsProvider: @escaping RecordsProvider,
                deleteRecordAction: @escaping DeleteRecordAction) {
        self.recordsProvider = recordsProvider
        self.deleteRecordAction = deleteRecordAction
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
                            titleHtml: record.title,
                            description: record.description,
                            imageURL: getURL(record.imageURL))
            }
            return HistorySection(dateWithoutTime: day, items: items)
        }

        return sections.sorted(by: { $0.dateWithoutTime > $1.dateWithoutTime })
    }

    func getURL(_ string: String?) -> URL? {
        guard let string else { return nil } 
        return URL(string: string)
    }
    /// Deletes a single history record by its identifier.
    /// - Parameter id: The identifier of the record to be deleted
    public func deleteHistoryItem(with section: HistorySection, _ item: HistoryItem) {
        deleteRecordAction(section, item)
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
    public let titleHtml: String
    public let description: String?
    public let imageURL: URL?

    public init(id: String, titleHtml: String, description: String? = nil, imageURL: URL? = nil) {
        self.id = id
        self.titleHtml = titleHtml
        self.description = description
        self.imageURL = imageURL
    }

    public static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return lhs.id == rhs.id
    }
}
