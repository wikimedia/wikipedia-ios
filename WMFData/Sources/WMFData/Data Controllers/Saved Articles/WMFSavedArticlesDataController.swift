import Foundation

public actor WMFSavedArticlesDataController {

    // MARK: - Properties

    public static let shared = WMFSavedArticlesDataController()
    private let articleSummaryDataController: WMFArticleSummaryDataController
    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    // MARK: - Lifecycle

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore,
                articleSummaryDataController: WMFArticleSummaryDataController = .init()
    ) {
        self._coreDataStore = coreDataStore
        self.articleSummaryDataController = articleSummaryDataController
    }

    // MARK: - Public API

    public func getSavedArticleModuleData(from startDate: Date, to endDate: Date) async -> SavedArticleModuleData? {
        guard let pages = try? await fetchSavedArticleSnapshots(startDate: startDate, endDate: endDate) else { return nil }

        var lastDate: Date?

        if let lastDateSaved = pages.first?.savedDate {
            lastDate = lastDateSaved
        }

        let titleURLTuples = await fetchSavedArticlesImageURLs(for: pages)

        let articleThumbTuples = Array(
            titleURLTuples
                .filter { $0.1 != nil } // only non-nil URLS
                .prefix(3)
        )

        let thumbURLs = articleThumbTuples.map { $0.1! }

        let titles = articleThumbTuples.map { $0.0 }

        return SavedArticleModuleData(savedArticlesCount: pages.count, articleThumbURLs: thumbURLs, dateLastSaved: lastDate, articleTitles: titles)
    }

    // MARK: - Private functions

    private func fetchSavedArticleSnapshots(startDate: Date, endDate: Date) async throws -> [SavedArticleSnapshot] {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        let context = try coreDataStore.newBackgroundContext

        let startNSDate = startDate as NSDate
        let endNSDate = endDate as NSDate

        return try await context.perform { () throws -> [SavedArticleSnapshot] in
            let sortDescriptor = NSSortDescriptor(key: "savedInfo.savedDate", ascending: false)
            let predicate = NSPredicate(
                format: "savedInfo != nil AND savedInfo.savedDate >= %@ AND savedInfo.savedDate <= %@",
                startNSDate, endNSDate
            )

            guard
                let pages: [CDPage] = try coreDataStore.fetch(
                    entityType: CDPage.self,
                    predicate: predicate,
                    fetchLimit: nil,
                    sortDescriptors: [sortDescriptor],
                    in: context
                )
            else { return [] }

            var snapshots: [SavedArticleSnapshot] = []
            snapshots.reserveCapacity(pages.count)

            for page in pages {
                guard
                    let projectID = page.projectID,
                    let title = page.title, !title.isEmpty
                else { continue }

                let project = WMFProject(id: projectID)
                let url = project?.siteURL?.wmfURL(withTitle: title, languageVariantCode: nil)

                let date = page.savedInfo?.savedDate

                snapshots.append(
                    SavedArticleSnapshot(
                        projectID: projectID,
                        title: title,
                        namespaceID: page.namespaceID,
                        savedDate: date,
                        articleURL: url
                    )
                )
            }
            return snapshots
        }
    }

    public func fetchTimelinePages() async throws -> [WMFPageWithTimestamp] {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        let context = try coreDataStore.newBackgroundContext

        return try await context.perform {
            let sortDescriptor = NSSortDescriptor(key: "savedInfo.savedDate", ascending: false)
            let predicate = NSPredicate(format: "savedInfo != nil")

            guard
                let pages: [CDPage] = try coreDataStore.fetch(
                    entityType: CDPage.self,
                    predicate: predicate,
                    fetchLimit: 1000,
                    sortDescriptors: [sortDescriptor],
                    in: context
                )
            else { return [] }

            var result: [WMFPageWithTimestamp] = []

            for page in pages {
                guard
                    let projectID = page.projectID,
                    let title = page.title,
                    let saved = page.savedInfo?.savedDate
                else { continue }

                let wmfPage = WMFPage(
                    namespaceID: Int(page.namespaceID),
                    projectID: projectID,
                    title: title
                )

                result.append(WMFPageWithTimestamp(page: wmfPage, timestamp: saved))
            }

            return result
        }

    }

    private func fetchSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary {
        try await withCheckedThrowingContinuation { continuation in
            articleSummaryDataController.fetchArticleSummary(project: project, title: title) { result in
                switch result {
                case .success(let summary):
                    continuation.resume(returning: summary)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchSavedArticlesImageURLs(for snapshots: [SavedArticleSnapshot]) async -> [(String, URL?)] {
        guard !snapshots.isEmpty else { return [] }

        return await withTaskGroup(of: (Int, String, URL?).self) { group in
            for (index, snap) in snapshots.enumerated() {
                group.addTask { [snap, index] in
                    guard let project = WMFProject(id: snap.projectID) else {
                        return (index, snap.title, nil)
                    }

                    do {
                        let summary = try await self.fetchSummary(
                            project: project,
                            title: snap.title
                        )
                        return (index, snap.title, summary.thumbnailURL)
                    } catch {
                        return (index, snap.title, nil)
                    }
                }
            }

            var results = [(String, URL?)](repeating: ("", nil), count: snapshots.count)

            for await (index, title, url) in group {
                results[index] = (title, url)
            }

            return results
        }
    }

}

// MARK: - Types

/// Helper struct for lighter data access
fileprivate struct SavedArticleSnapshot: Sendable {
    let projectID: String
    let title: String
    let namespaceID: Int16
    let savedDate: Date?
    let articleURL: URL?
}

public struct SavedArticleModuleData: Codable {
    public let savedArticlesCount: Int
    public let articleThumbURLs: [URL?]
    public let dateLastSaved: Date?
    public let articleTitles: [String]

    public init(
        savedArticlesCount: Int,
        articleThumbURLs: [URL?],
        dateLastSaved: Date?,
        articleTitles: [String]
    ) {
        self.savedArticlesCount = savedArticlesCount
        self.articleThumbURLs = articleThumbURLs
        self.dateLastSaved = dateLastSaved
        self.articleTitles = articleTitles
    }
}

