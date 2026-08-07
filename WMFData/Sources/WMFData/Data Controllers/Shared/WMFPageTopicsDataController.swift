import Foundation
import CoreData

/// Persists the topics an article belongs to, keyed on the same `CDPage` that reading history hangs off of,
/// so that topics can be aggregated over a period of reading history.
// @unchecked Sendable: coreDataStore is an immutable let; all mutations go through backgroundContext.perform { }
public final class WMFPageTopicsDataController: @unchecked Sendable {

    /// Maximum number of topics persisted for a single article.
    static let maximumTopicsPerPage = 5

    private let coreDataStore: WMFCoreDataStore

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
    }

    // MARK: - Saving

    /// Replaces an article's stored topics with `topics`.
    ///
    /// An empty payload is treated as "no topic data available" rather than "this article's topics were
    /// removed", so it leaves any previously stored topics untouched.
    public func savePageTopics(title: String, namespaceID: Int16, project: WMFProject, topics: [WMFPageTopic]) async throws {

        let sanitizedTopics = Self.sanitized(topics)

        guard !sanitizedTopics.isEmpty else {
            return
        }

        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        try await backgroundContext.perform { [weak self] in

            guard let self else { return }

            let predicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])

            // Topics arrive as the article finishes loading, which can beat the page view write to the
            // database, so create the page if it isn't there yet.
            let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: predicate, in: backgroundContext)
            page?.title = coreDataTitle
            page?.namespaceID = namespaceID
            page?.projectID = project.id
            if page?.timestamp == nil {
                page?.timestamp = Date()
            }

            // Replace wholesale in the same transaction, so re-reading an article whose topics changed
            // upstream doesn't leave stale rows behind.
            if let existingTopics = page?.topics as? Set<CDPageTopic> {
                for existingTopic in existingTopics {
                    backgroundContext.delete(existingTopic)
                }
            }

            for topic in sanitizedTopics {
                let cdTopic = try self.coreDataStore.create(entityType: CDPageTopic.self, in: backgroundContext)
                cdTopic.topic = topic.topic
                cdTopic.score = topic.score
                cdTopic.page = page
            }

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    /// Drops empty topic names, de-duplicates by name keeping the highest score, orders by score descending
    /// and caps the result at `maximumTopicsPerPage`.
    static func sanitized(_ topics: [WMFPageTopic]) -> [WMFPageTopic] {

        var highestScoresByTopic: [String: Double] = [:]

        for topic in topics {
            let name = topic.topic.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !name.isEmpty else { continue }

            if let existingScore = highestScoresByTopic[name], existingScore >= topic.score {
                continue
            }

            highestScoresByTopic[name] = topic.score
        }

        let sorted = highestScoresByTopic
            .map { WMFPageTopic(topic: $0.key, score: $0.value) }
            .sorted {
                if $0.score != $1.score {
                    return $0.score > $1.score
                }
                return $0.topic < $1.topic
            }

        return Array(sorted.prefix(maximumTopicsPerPage))
    }

    // MARK: - Fetching

    /// Topics stored for a single article, ordered by score descending.
    public func fetchTopics(title: String, namespaceID: Int16, project: WMFProject) async throws -> [WMFPageTopic] {

        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext

        return try await backgroundContext.perform { [weak self] () -> [WMFPageTopic] in

            guard let self else { return [] }

            let predicate = NSPredicate(format: "page.projectID == %@ && page.namespaceID == %@ && page.title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])
            let sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]

            let cdTopics = try self.coreDataStore.fetch(entityType: CDPageTopic.self, predicate: predicate, fetchLimit: nil, sortDescriptors: sortDescriptors, in: backgroundContext) ?? []

            return cdTopics.compactMap { cdTopic in
                guard let topic = cdTopic.topic else { return nil }
                return WMFPageTopic(topic: topic, score: cdTopic.score)
            }
        }
    }

    /// The topics the user read the most distinct articles about within the period, most articles first.
    public func fetchTopTopicsByArticleCount(startDate: Date, endDate: Date, limit: Int) async throws -> [WMFTopicReadingSummary] {

        let summaries = try await fetchTopicReadingSummaries(startDate: startDate, endDate: endDate)

        let sorted = summaries.sorted {
            if $0.articleCount != $1.articleCount {
                return $0.articleCount > $1.articleCount
            }
            if $0.timeSpentSeconds != $1.timeSpentSeconds {
                return $0.timeSpentSeconds > $1.timeSpentSeconds
            }
            return $0.topic < $1.topic
        }

        return Array(sorted.prefix(limit))
    }

    /// The topics the user spent the most time reading about within the period, most time first.
    public func fetchTopTopicsByTimeSpent(startDate: Date, endDate: Date, limit: Int) async throws -> [WMFTopicReadingSummary] {

        let summaries = try await fetchTopicReadingSummaries(startDate: startDate, endDate: endDate)

        let sorted = summaries.sorted {
            if $0.timeSpentSeconds != $1.timeSpentSeconds {
                return $0.timeSpentSeconds > $1.timeSpentSeconds
            }
            if $0.articleCount != $1.articleCount {
                return $0.articleCount > $1.articleCount
            }
            return $0.topic < $1.topic
        }

        return Array(sorted.prefix(limit))
    }

    private func fetchTopicReadingSummaries(startDate: Date, endDate: Date) async throws -> [WMFTopicReadingSummary] {

        let backgroundContext = try coreDataStore.newBackgroundContext

        return try await backgroundContext.perform { [weak self] () -> [WMFTopicReadingSummary] in

            guard let self else { return [] }

            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@", startDate as CVarArg, endDate as CVarArg)

            guard let pageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, predicate: predicate, fetchLimit: nil, in: backgroundContext) else {
                return []
            }

            // Reduce to distinct articles before aggregating, so an article read ten times counts once.
            // Seconds are recorded per page view rather than per page, so they are totalled per article
            // here and then attributed to each of that article's topics exactly once below.
            var secondsByPage: [CDPage: Int64] = [:]
            for pageView in pageViews {
                guard let page = pageView.page else { continue }
                secondsByPage[page, default: 0] += pageView.numberOfSeconds
            }

            var totalsByTopic: [String: (articleCount: Int, seconds: Int64)] = [:]
            for (page, seconds) in secondsByPage {
                guard let cdTopics = page.topics as? Set<CDPageTopic> else { continue }

                for cdTopic in cdTopics {
                    guard let topic = cdTopic.topic else { continue }

                    var total = totalsByTopic[topic] ?? (articleCount: 0, seconds: 0)
                    total.articleCount += 1
                    total.seconds += seconds
                    totalsByTopic[topic] = total
                }
            }

            return totalsByTopic.map { WMFTopicReadingSummary(topic: $0.key, articleCount: $0.value.articleCount, timeSpentSeconds: Int($0.value.seconds)) }
        }
    }

    /// Articles in the user's reading history for the period that belong to `topic`, most recently read first.
    /// An article read repeatedly appears once, at its most recent view.
    public func fetchPages(forTopic topic: String, startDate: Date, endDate: Date, limit: Int) async throws -> [WMFPageWithTimestamp] {

        let backgroundContext = try coreDataStore.newBackgroundContext

        return try await backgroundContext.perform { [weak self] () -> [WMFPageWithTimestamp] in

            guard let self else { return [] }

            let predicate = NSPredicate(format: "timestamp >= %@ && timestamp <= %@ && ANY page.topics.topic == %@", startDate as CVarArg, endDate as CVarArg, topic)
            let sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            guard let pageViews = try self.coreDataStore.fetch(entityType: CDPageView.self, predicate: predicate, fetchLimit: nil, sortDescriptors: sortDescriptors, in: backgroundContext) else {
                return []
            }

            var seenPages = Set<CDPage>()
            var results: [WMFPageWithTimestamp] = []

            for pageView in pageViews {
                guard let page = pageView.page,
                      let projectID = page.projectID,
                      let title = page.title,
                      let timestamp = pageView.timestamp else { continue }

                guard seenPages.insert(page).inserted else { continue }

                let wmfPage = WMFPage(namespaceID: Int(page.namespaceID), projectID: projectID, title: title)
                results.append(WMFPageWithTimestamp(page: wmfPage, timestamp: timestamp))

                if results.count == limit {
                    break
                }
            }

            return results
        }
    }

    // MARK: - Deleting

    func deleteTopics(title: String, namespaceID: Int16, project: WMFProject) async throws {

        let coreDataTitle = title.normalizedForCoreData
        let backgroundContext = try coreDataStore.newBackgroundContext
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        try await backgroundContext.perform { [weak self] in

            guard let self else { return }

            let predicate = NSPredicate(format: "page.projectID == %@ && page.namespaceID == %@ && page.title == %@", argumentArray: [project.id, namespaceID, coreDataTitle])

            guard let cdTopics = try self.coreDataStore.fetch(entityType: CDPageTopic.self, predicate: predicate, fetchLimit: nil, in: backgroundContext) else {
                return
            }

            for cdTopic in cdTopics {
                backgroundContext.delete(cdTopic)
            }

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
}
