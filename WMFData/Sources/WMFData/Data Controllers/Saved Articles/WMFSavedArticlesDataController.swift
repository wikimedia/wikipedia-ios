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
        guard let pages = try? await fetchSavedArticleSnapshots(startDate: startDate, endDate: endDate) else {return nil}

        var lastDate: Date?
        var randomURLs: [URL?] = []

        if let lastDateSaved = pages.first?.savedDate {
            lastDate = lastDateSaved
        }

        let random3articles = pages
            .compactMap { $0 }
            .shuffled()
            .prefix(3)
            .map { $0 }

        if let thumbnailURLs = try? await fetchSavedArticlesImageURLs(for: random3articles) {
            randomURLs = thumbnailURLs
        }

        return SavedArticleModuleData(savedArticlesCount: pages.count, articleThumbURLs: randomURLs, dateLastSaved: lastDate)
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

    private func fetchSavedArticlesImageURLs(for snapshots: [SavedArticleSnapshot]) async throws -> [URL?] {
        guard !snapshots.isEmpty else { return [] }

        return await withTaskGroup(of: URL?.self) { group in
            for snap in snapshots {
                group.addTask { [snap] in
                    guard let project = WMFProject(id: snap.projectID) else { return nil }
                    do {
                        let summary = try await self.fetchSummary(project: project, title: snap.title)
                        return summary.thumbnailURL
                    } catch {
                        return nil
                    }
                }
            }

            var urls: [URL?] = []
            urls.reserveCapacity(snapshots.count)

            for await url in group {
                if let url {
                    urls.append(url)
                }
            }
            return urls
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

    public init(savedArticlesCount: Int, articleThumbURLs: [URL?], dateLastSaved: Date?) {
        self.savedArticlesCount = savedArticlesCount
        self.articleThumbURLs = articleThumbURLs
        self.dateLastSaved = dateLastSaved
    }
}
