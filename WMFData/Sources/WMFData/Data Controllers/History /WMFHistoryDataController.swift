import Foundation

/// A plain‐Swift struct representing a single record or WMFArticle from the user’s read history, exactly as it’s stored in WMKDataStore
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
    public let variant: String?

    public init(id: Int, title: String, descriptionOrSnippet: String?, shortDescription: String?, articleURL: URL?, imageURL: String?, viewedDate: Date, isSaved: Bool, snippet: String?, variant: String?) {
        self.id = id
        self.title = title
        self.descriptionOrSnippet = descriptionOrSnippet
        self.shortDescription = shortDescription
        self.articleURL = articleURL
        self.imageURL = imageURL
        self.viewedDate = viewedDate
        self.isSaved = isSaved
        self.snippet = snippet
        self.variant = variant
    }
}

public final class WMFHistoryDataController: WMFHistoryDataControllerProtocol {

    // MARK: - Dependency Injection Closures

    /// Closure that returns an array of history records
    public typealias RecordsProvider = () -> [HistoryRecord]

    /// Closure that deletes a single history record
    public typealias DeleteRecordAction = (HistoryItem) -> Void

    /// Closure to pass an item to be saved on the data store
    public typealias SaveRecordAction = (HistoryItem) -> Void

    /// Closure to pass an item to be unsaved from the data store
    public typealias UnsaveRecordAction = (HistoryItem) -> Void

    private let recordsProvider: RecordsProvider
    public var deleteRecordAction: DeleteRecordAction?
    public var saveRecordAction: SaveRecordAction?
    public var unsaveRecordAction: UnsaveRecordAction?

    /// Initializes the history data controller.
    /// - Parameters:
    ///   - recordsProvider: A closure returning an array of `HistoryRecord`.
    public init(recordsProvider: @escaping RecordsProvider) {
        self.recordsProvider = recordsProvider
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
                            description: record.descriptionOrSnippet,
                            shortDescription: record.shortDescription,
                            imageURLString: record.imageURL,
                            isSaved: record.isSaved,
                            snippet: record.snippet,
                            variant: record.variant
                )
            }
            return HistorySection(dateWithoutTime: day, items: items)
        }

        return sections.sorted(by: { $0.dateWithoutTime > $1.dateWithoutTime })
    }

    public func deleteHistoryItem(_ item: HistoryItem) {
        deleteRecordAction?(item)
    }

    public func saveHistoryItem(_ item: HistoryItem) {
        saveRecordAction?(item)
    }

    public func unsaveHistoryItem(_ item: HistoryItem) {
        unsaveRecordAction?(item)
    }

}


public protocol WMFHistoryDataControllerProtocol {
    // MARK: - Dependency Injection Typealiases

    /// Closure that returns an array of history records.
    typealias RecordsProvider = () -> [HistoryRecord]

    /// Closure that deletes a single history record.
    typealias DeleteRecordAction = (HistoryItem) -> Void

    /// Closure that saves a history record.
    typealias SaveRecordAction = (HistoryItem) -> Void

    /// Closure that unsaves a history record.
    typealias UnsaveRecordAction = (HistoryItem) -> Void

    // MARK: - Data Access Methods

    /// Groups history records by day and returns an array of HistorySection.
    func fetchHistorySections() -> [HistorySection]

    /// Deletes the specified history item.
    func deleteHistoryItem(_ item: HistoryItem)

    /// Saves the specified history item.
    func saveHistoryItem(_ item: HistoryItem)

    /// Un-saves the specified history item.
    func unsaveHistoryItem(_ item: HistoryItem)
}

/// Representation of a section of a list of history items
public final class HistorySection: Identifiable, Equatable {
    public static func == (lhs: HistorySection, rhs: HistorySection) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let dateWithoutTime: Date
    @Published public var items: [HistoryItem]
    public let id: String

    public init(dateWithoutTime: Date, items: [HistoryItem]) {
        self.dateWithoutTime = dateWithoutTime
        self.items = items
        self.id = UUID().uuidString
    }
}

/// A view‐layer representation of a history record, for use in SwiftUI lists.
/// Converts raw data from `HistoryRecord` into types and bindings that UI code can work and update
public final class HistoryItem: Identifiable, Equatable {
    public let id: String
    public let url: URL?
    public let titleHtml: String
    public let description: String?
    public let shortDescription: String?
    public let imageURLString: String?
    public var isSaved: Bool
    public let snippet: String?
    public let variant: String?

    public init(id: String, url: URL?, titleHtml: String, description: String?, shortDescription: String?, imageURLString: String?, isSaved: Bool, snippet: String?, variant: String?) {
        self.id = id
        self.url = url
        self.titleHtml = titleHtml
        self.description = description
        self.shortDescription = shortDescription
        self.imageURLString = imageURLString
        self.isSaved = isSaved
        self.snippet = snippet
        self.variant = variant
    }

    public static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return lhs.id == rhs.id
    }
}
