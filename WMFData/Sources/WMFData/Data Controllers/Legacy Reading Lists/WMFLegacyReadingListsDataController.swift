import Foundation

/// The app side implements this with the legacy Core Data store (`ReadingList`, `ReadingListEntry`,
/// `WMFArticle`) and `ReadingListsController`. It returns raw, unsorted data. Sorting, searching and
/// filtering live in `WMFLegacyReadingListsDataController`, where they are unit tested.
public protocol WMFLegacyReadingListsDataControllerDelegate: AnyObject {
    func fetchSavedArticles() async throws -> [WMFSavedArticle]
    func fetchReadingLists() async throws -> [WMFReadingList]
    func fetchArticles(inReadingList readingListID: String) async throws -> [WMFSavedArticle]
    func defaultReadingListID() async throws -> String?
    func isDefaultReadingListEnabled() async -> Bool

    func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder?
    func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws

    func createReadingList(name: String, description: String?) async throws -> WMFReadingList
    func updateReadingList(id readingListID: String, name: String?, description: String?) async throws
    func deleteReadingLists(ids readingListIDs: [String]) async throws
    func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws
    func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws
    func unsaveArticles(ids articleIDs: [String]) async throws

    /// Transitional: the confirmation alert still lives app-side until the SwiftUI screens own it.
    func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void)
}

public enum WMFLegacyReadingListsDataControllerError: Error {
    case missingDelegate
}

/// Reading lists and saved articles for the Saved tab, on top of the legacy store.
///
/// @unchecked: the only mutable state is the weak delegate reference, assigned once during
/// app-side wiring (the CLAUDE.md "legacy persistence" bridge pattern) and read afterward.
public final class WMFLegacyReadingListsDataController: @unchecked Sendable {

    public weak var delegate: WMFLegacyReadingListsDataControllerDelegate?
    private let userDefaultsStore: WMFKeyValueStore?

    public init(delegate: WMFLegacyReadingListsDataControllerDelegate? = nil, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore) {
        self.delegate = delegate
        self.userDefaultsStore = userDefaultsStore
    }

    private func requireDelegate() throws -> WMFLegacyReadingListsDataControllerDelegate {
        guard let delegate else {
            throw WMFLegacyReadingListsDataControllerError.missingDelegate
        }
        return delegate
    }

    // MARK: - Saved articles (All articles segment)

    /// Every saved article, sorted by `savedArticlesSortOrder()` and narrowed to `searchText`.
    public func fetchSavedArticles(searchText: String = "") async throws -> [WMFSavedArticle] {
        let delegate = try requireDelegate()
        let articles = try await delegate.fetchSavedArticles()
        let sortOrder = try await savedArticlesSortOrder()
        return Self.sorted(Self.filtered(articles, searchText: searchText), by: sortOrder)
    }

    // MARK: - Reading lists segment

    /// The lists for a screen, the default list first when it is shown, then sorted by `readingListsSortOrder`.
    public func fetchReadingLists(filter: WMFReadingListsFilter = .all, searchText: String = "") async throws -> [WMFReadingList] {
        let delegate = try requireDelegate()
        let lists = try await delegate.fetchReadingLists()
        let isDefaultListEnabled = await delegate.isDefaultReadingListEnabled()
        let visible = Self.filtered(lists, filter: filter, isDefaultListEnabled: isDefaultListEnabled)
        return Self.sorted(Self.filtered(visible, searchText: searchText), by: readingListsSortOrder)
    }

    // MARK: - Reading list detail

    /// The articles in one list, sorted by that list's own sort order.
    public func fetchArticles(inReadingList readingListID: String, searchText: String = "") async throws -> [WMFSavedArticle] {
        let delegate = try requireDelegate()
        let articles = try await delegate.fetchArticles(inReadingList: readingListID)
        let sortOrder = try await delegate.sortOrder(forReadingList: readingListID) ?? .byRecentlyAdded
        return Self.sorted(Self.filtered(articles, searchText: searchText), by: sortOrder)
    }

    // MARK: - Sort order

    /// The All articles sort is stored on the default reading list, as before the rewrite.
    public func savedArticlesSortOrder() async throws -> WMFReadingListSortOrder {
        let delegate = try requireDelegate()
        guard let defaultID = try await delegate.defaultReadingListID() else {
            return .byRecentlyAdded
        }
        return try await delegate.sortOrder(forReadingList: defaultID) ?? .byRecentlyAdded
    }

    public func setSavedArticlesSortOrder(_ sortOrder: WMFReadingListSortOrder) async throws {
        let delegate = try requireDelegate()
        guard let defaultID = try await delegate.defaultReadingListID() else {
            return
        }
        try await delegate.setSortOrder(sortOrder, forReadingList: defaultID)
    }

    /// The Reading lists segment sort. Stored on device so it survives a relaunch.
    public var readingListsSortOrder: WMFReadingListSortOrder {
        let rawValue: Int? = try? userDefaultsStore?.load(key: WMFUserDefaultsKey.readingListsSortOrder.rawValue)
        return rawValue.flatMap(WMFReadingListSortOrder.init(rawValue:)) ?? .byTitle
    }

    public func setReadingListsSortOrder(_ sortOrder: WMFReadingListSortOrder) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.readingListsSortOrder.rawValue, value: sortOrder.rawValue)
    }

    public func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder {
        try await requireDelegate().sortOrder(forReadingList: readingListID) ?? .byRecentlyAdded
    }

    public func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws {
        try await requireDelegate().setSortOrder(sortOrder, forReadingList: readingListID)
    }

    // MARK: - Mutations

    public func createReadingList(name: String, description: String?) async throws -> WMFReadingList {
        try await requireDelegate().createReadingList(name: name, description: description)
    }

    public func updateReadingList(id readingListID: String, name: String?, description: String?) async throws {
        try await requireDelegate().updateReadingList(id: readingListID, name: name, description: description)
    }

    public func deleteReadingLists(ids readingListIDs: [String]) async throws {
        try await requireDelegate().deleteReadingLists(ids: readingListIDs)
    }

    public func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws {
        try await requireDelegate().addArticles(ids: articleIDs, toReadingList: readingListID)
    }

    public func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws {
        try await requireDelegate().removeArticles(ids: articleIDs, fromReadingList: readingListID)
    }

    /// Move = add to the destination, then remove from the source. The add runs first so a
    /// failure leaves the articles where they were.
    public func moveArticles(ids articleIDs: [String], fromReadingList sourceID: String, toReadingList destinationID: String) async throws {
        let delegate = try requireDelegate()
        try await delegate.addArticles(ids: articleIDs, toReadingList: destinationID)
        try await delegate.removeArticles(ids: articleIDs, fromReadingList: sourceID)
    }

    public func unsaveArticles(ids articleIDs: [String]) async throws {
        try await requireDelegate().unsaveArticles(ids: articleIDs)
    }

    /// Transitional, see the delegate.
    public func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) {
        delegate?.deleteSavedArticles(articles: articles, fromLongPress: fromLongPress, completion: completion)
    }

    // MARK: - Rules

    /// Title order uses the display title, ignores case and accents and follows the device locale. Ties go to the newest.
    public static func sorted(_ articles: [WMFSavedArticle], by sortOrder: WMFReadingListSortOrder) -> [WMFSavedArticle] {
        articles.sorted { lhs, rhs in
            switch sortOrder {
            case .byTitle:
                let comparison = lhs.displayTitle.localizedStandardCompare(rhs.displayTitle)
                if comparison != .orderedSame {
                    return comparison == .orderedAscending
                }
                return isNewer(lhs.savedDate, than: rhs.savedDate)
            case .byRecentlyAdded:
                if lhs.savedDate != rhs.savedDate {
                    return isNewer(lhs.savedDate, than: rhs.savedDate)
                }
                return lhs.displayTitle.localizedStandardCompare(rhs.displayTitle) == .orderedAscending
            }
        }
    }

    /// The default list always comes first. The rest follow the same title and date rules as articles.
    public static func sorted(_ lists: [WMFReadingList], by sortOrder: WMFReadingListSortOrder) -> [WMFReadingList] {
        lists.sorted { lhs, rhs in
            if lhs.isDefault != rhs.isDefault {
                return lhs.isDefault
            }
            switch sortOrder {
            case .byTitle:
                let comparison = lhs.name.localizedStandardCompare(rhs.name)
                if comparison != .orderedSame {
                    return comparison == .orderedAscending
                }
                return isNewer(lhs.createdDate, than: rhs.createdDate)
            case .byRecentlyAdded:
                if lhs.createdDate != rhs.createdDate {
                    return isNewer(lhs.createdDate, than: rhs.createdDate)
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }

    /// Case- and accent-insensitive "contains", like the legacy `CONTAINS[cd]` predicate.
    public static func matches(_ text: String, searchText: String) -> Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return true
        }
        return text.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    static func filtered(_ articles: [WMFSavedArticle], searchText: String) -> [WMFSavedArticle] {
        articles.filter { matches($0.displayTitle, searchText: searchText) }
    }

    static func filtered(_ lists: [WMFReadingList], searchText: String) -> [WMFReadingList] {
        lists.filter { matches($0.name, searchText: searchText) }
    }

    static func filtered(_ lists: [WMFReadingList], filter: WMFReadingListsFilter, isDefaultListEnabled: Bool) -> [WMFReadingList] {
        switch filter {
        case .all:
            return lists.filter { !$0.isDefault || isDefaultListEnabled }
        case .excludingListsContainingAll(let articleIDs):
            return lists.filter { list in
                guard !list.isDefault || isDefaultListEnabled else {
                    return false
                }
                return !articleIDs.isSubset(of: list.articleIDs)
            }
        case .named(let names):
            return lists.filter { names.contains($0.name) }
        }
    }

    /// nil dates sort last.
    private static func isNewer(_ lhs: Date?, than rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs > rhs
        case (.some, .none):
            return true
        default:
            return false
        }
    }
}
