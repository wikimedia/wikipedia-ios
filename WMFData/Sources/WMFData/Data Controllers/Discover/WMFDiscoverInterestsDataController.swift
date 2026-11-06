import Foundation
import CoreData

/// Stores the interests the Discover reading list is built from, and suggests articles for the
/// interests screen to show before the reader picks anything.
///
/// Each interest is one `CDDiscoverInterest` row: a topic row holds the topic raw value, a page
/// row points at its `CDPage`. The For You interests live in `CDPageInterest`, so a change on
/// one screen never shows on the other. The Discover list compares the stored set with the one it
/// was built from on its next generation check, so a changed set regenerates the list.
public actor WMFDiscoverInterestsDataController {

    public static let shared = WMFDiscoverInterestsDataController()

    /// How many suggested articles the interests screen shows at most. Matches Android.
    public static let maximumSuggestedPages = 20

    private let injectedCoreDataStore: WMFCoreDataStore?
    private let injectedUserDefaultsStore: WMFKeyValueStore?

    /// Stores default to the environment at call time, because the Core Data store is created
    /// asynchronously during launch and may not exist yet when `shared` is first touched.
    public init(coreDataStore: WMFCoreDataStore? = nil, userDefaultsStore: WMFKeyValueStore? = nil) {
        self.injectedCoreDataStore = coreDataStore
        self.injectedUserDefaultsStore = userDefaultsStore
    }

    private var coreDataStore: WMFCoreDataStore? {
        injectedCoreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    private var userDefaultsStore: WMFKeyValueStore? {
        injectedUserDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore
    }

    private func requireCoreDataStore() throws -> WMFCoreDataStore {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        return coreDataStore
    }

    private var cachedWriterContext: NSManagedObjectContext?
    private weak var cachedWriterContextStore: WMFCoreDataStore?

    /// One context for every write. The actor is free while a block runs, so two writes can be
    /// in flight at once. The context runs its blocks one after the other, thus the read, change and
    /// save of one write never overlap another one, and every write has the same merge policy.
    private func writerContext(for coreDataStore: WMFCoreDataStore) throws -> NSManagedObjectContext {
        if let cachedWriterContext, cachedWriterContextStore === coreDataStore {
            return cachedWriterContext
        }
        let context = try coreDataStore.newBackgroundContext
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        context.automaticallyMergesChangesFromParent = true
        cachedWriterContext = context
        cachedWriterContextStore = coreDataStore
        return context
    }

    // MARK: - Interests

    /// Topics and pages in the order the reader selected them.
    public func fetchInterests() async throws -> WMFDiscoverInterests {
        let coreDataStore = try requireCoreDataStore()
        let context = try coreDataStore.newBackgroundContext
        return try await context.perform {
            let rows = try Self.fetchRows(predicate: nil, coreDataStore: coreDataStore, in: context)
            let topics = rows.compactMap { row in row.topic.flatMap(WMFArticleTopic.init(rawValue:)) }
            let pages = rows.compactMap { row -> WMFDiscoverInterests.Page? in
                guard let page = row.page, let title = page.title, let projectID = page.projectID, let project = WMFProject(id: projectID) else {
                    return nil
                }
                return WMFDiscoverInterests.Page(title: title.underscoresToSpaces, project: project)
            }
            return WMFDiscoverInterests(topics: topics, pages: pages)
        }
    }

    /// Replaces the stored set. A page that names an article already in the list, in any spacing of
    /// the title, is left out, because one `CDPage` can hold one interest only.
    /// The Discover list compares the set with the one it was built from on its next generation
    /// check, so a changed set regenerates the list.
    public func save(_ newInterests: WMFDiscoverInterests) async throws {
        let coreDataStore = try requireCoreDataStore()
        let context = try writerContext(for: coreDataStore)

        try await context.perform {
            try Self.deleteRows(predicate: nil, coreDataStore: coreDataStore, in: context)
            try Self.insertTopics(newInterests.topics, coreDataStore: coreDataStore, in: context)
            var insertedPages: [WMFDiscoverInterests.Page] = []
            for page in newInterests.pages where !insertedPages.contains(where: { $0.matches(page) }) {
                try Self.insertPage(page, sortIndex: Int32(insertedPages.count), coreDataStore: coreDataStore, in: context)
                insertedPages.append(page)
            }
            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    public func setTopics(_ topics: [WMFArticleTopic]) async throws {
        let coreDataStore = try requireCoreDataStore()
        let context = try writerContext(for: coreDataStore)

        try await context.perform {
            try Self.deleteRows(predicate: NSPredicate(format: "topic != nil"), coreDataStore: coreDataStore, in: context)
            try Self.insertTopics(topics, coreDataStore: coreDataStore, in: context)
            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    /// Adds an article once. A page already in the set, in any spacing of the title, is left as it is.
    public func addPage(title: String, project: WMFProject) async throws {
        let coreDataStore = try requireCoreDataStore()
        let context = try writerContext(for: coreDataStore)

        try await context.perform {
            if try Self.fetchPageRow(title: title, project: project, coreDataStore: coreDataStore, in: context) != nil {
                return
            }

            let nextSortIndex = try Self.highestPageSortIndex(coreDataStore: coreDataStore, in: context) + 1
            try Self.insertPage(WMFDiscoverInterests.Page(title: title, project: project), sortIndex: nextSortIndex, coreDataStore: coreDataStore, in: context)
            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    public func removePage(title: String, project: WMFProject) async throws {
        let coreDataStore = try requireCoreDataStore()
        let context = try writerContext(for: coreDataStore)

        try await context.perform {
            guard let row = try Self.fetchPageRow(title: title, project: project, coreDataStore: coreDataStore, in: context) else {
                return
            }
            context.delete(row)
            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    public func removeAll() async throws {
        let coreDataStore = try requireCoreDataStore()
        let context = try writerContext(for: coreDataStore)

        try await context.perform {
            try Self.deleteRows(predicate: nil, coreDataStore: coreDataStore, in: context)
            try coreDataStore.saveIfNeeded(moc: context)
        }
    }

    // MARK: - Rows

    private static func fetchRows(predicate: NSPredicate?, coreDataStore: WMFCoreDataStore, in context: NSManagedObjectContext) throws -> [CDDiscoverInterest] {
        let sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        return try coreDataStore.fetch(entityType: CDDiscoverInterest.self, predicate: predicate, fetchLimit: nil, sortDescriptors: sortDescriptors, in: context) ?? []
    }

    /// -1 when the set has no page, so the first page gets index 0.
    private static func highestPageSortIndex(coreDataStore: WMFCoreDataStore, in context: NSManagedObjectContext) throws -> Int32 {
        let sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: false)]
        let lastRow = try coreDataStore.fetch(entityType: CDDiscoverInterest.self, predicate: NSPredicate(format: "page != nil"), fetchLimit: 1, sortDescriptors: sortDescriptors, in: context)?.first
        return lastRow?.sortIndex ?? -1
    }

    private static func deleteRows(predicate: NSPredicate?, coreDataStore: WMFCoreDataStore, in context: NSManagedObjectContext) throws {
        for row in try fetchRows(predicate: predicate, coreDataStore: coreDataStore, in: context) {
            context.delete(row)
        }
    }

    private static func insertTopics(_ topics: [WMFArticleTopic], coreDataStore: WMFCoreDataStore, in context: NSManagedObjectContext) throws {
        for (index, topic) in topics.enumerated() {
            let row = try coreDataStore.create(entityType: CDDiscoverInterest.self, in: context)
            row.topic = topic.rawValue
            row.sortIndex = Int32(index)
        }
    }

    private static func insertPage(_ interestPage: WMFDiscoverInterests.Page, sortIndex: Int32, coreDataStore: WMFCoreDataStore, in context: NSManagedObjectContext) throws {
        let coreDataTitle = interestPage.title.normalizedForCoreData
        let predicate = pagePredicate(title: interestPage.title, project: interestPage.project)
        guard let page = try coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: context) else {
            return
        }
        page.title = coreDataTitle
        page.namespaceID = 0
        page.projectID = interestPage.project.id
        if page.timestamp == nil {
            page.timestamp = Date()
        }

        let row = try coreDataStore.create(entityType: CDDiscoverInterest.self, in: context)
        row.sortIndex = sortIndex
        row.page = page
    }

    /// The interest row of a page, found through the row and not through the page. `CDPage` has no
    /// uniqueness constraint, so a lookup of the page could land on a duplicate without an interest.
    private static func fetchPageRow(title: String, project: WMFProject, coreDataStore: WMFCoreDataStore, in context: NSManagedObjectContext) throws -> CDDiscoverInterest? {
        let predicate = NSPredicate(format: "page.projectID == %@ && page.namespaceID == %@ && page.title == %@", argumentArray: [project.id, Int16(0), title.normalizedForCoreData])
        return try coreDataStore.fetch(entityType: CDDiscoverInterest.self, predicate: predicate, fetchLimit: 1, in: context)?.first
    }

    private static func pagePredicate(title: String, project: WMFProject) -> NSPredicate {
        NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, Int16(0), title.normalizedForCoreData])
    }

    // MARK: - Suggestions

    /// Articles for the interests screen to offer: recently read pages and saved pages, one of each
    /// in turn, newest first, up to `limit`. Pages already in the set and pages outside the main
    /// namespace are left out. Matches the pre-filled grid on Android.
    public func suggestedPages(limit: Int = maximumSuggestedPages) async throws -> [WMFDiscoverInterests.Page] {
        let coreDataStore = try requireCoreDataStore()

        let historyPages = try await fetchHistoryPages(coreDataStore: coreDataStore)
        let savedPages = try await fetchSavedPages(coreDataStore: coreDataStore)
        let currentInterests = try await fetchInterests()

        var suggestions: [WMFDiscoverInterests.Page] = []
        func append(_ page: WMFDiscoverInterests.Page) {
            guard suggestions.count < limit,
                  !currentInterests.contains(page),
                  !suggestions.contains(where: { $0.matches(page) }) else {
                return
            }
            suggestions.append(page)
        }

        for index in 0..<max(historyPages.count, savedPages.count) {
            if index < historyPages.count {
                append(historyPages[index])
            }
            if index < savedPages.count {
                append(savedPages[index])
            }
        }

        return suggestions
    }

    /// Reading history is stored per project, so every app language is asked for its own pages.
    private func fetchHistoryPages(coreDataStore: WMFCoreDataStore) async throws -> [WMFDiscoverInterests.Page] {
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore)

        var pages: [WMFDiscoverInterests.Page] = []
        for language in WMFDataEnvironment.current.appData.appLanguages {
            let project = WMFProject.wikipedia(language)
            let recentlyReadPages = try await pageViewsDataController.fetchRecentlyReadPages(project: project, minimumSeconds: 0, withinDays: 365, mainNamespaceOnly: true)
            pages.append(contentsOf: recentlyReadPages.compactMap(WMFDiscoverInterests.Page.init(page:)))
        }

        return pages
    }

    private func fetchSavedPages(coreDataStore: WMFCoreDataStore) async throws -> [WMFDiscoverInterests.Page] {
        let savedArticlesDataController = WMFSavedArticlesDataController(coreDataStore: coreDataStore)
        let savedPages = try await savedArticlesDataController.fetchTimelinePages()
        return savedPages.compactMap { WMFDiscoverInterests.Page(page: $0.page) }
    }
}

private extension WMFDiscoverInterests.Page {

    /// Nil for pages outside the main namespace or from a project the app no longer knows.
    init?(page: WMFPage) {
        guard page.namespaceID == 0, let project = WMFProject(id: page.projectID) else {
            return nil
        }

        self.init(title: page.title.underscoresToSpaces, project: project)
    }
}
