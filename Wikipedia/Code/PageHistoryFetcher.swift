import Foundation
import WMF
import WMFData

public typealias EditCountsGroupedByType = [PageHistoryFetcher.EditCountType: (count: Int, limit: Bool)]

public final class PageHistoryFetcher: WMFLegacyFetcher {

    /// The number of revisions in one page. The last revision waits for the next page so that its size difference is known.
    private static let revisionsPerPage = 51

    func fetchRevisionInfo(_ siteURL: URL, requestParams: PageHistoryRequestParameters, failure: @escaping WMFErrorHandler, success: @escaping (HistoryFetchResults) -> Void) {
        guard let project = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            failure(RequestError.invalidParameters)
            return
        }

        Task {
            do {
                let page = try await WMFPageHistoryDataController.shared.fetchRevisions(
                    project: project,
                    title: requestParams.title,
                    limit: PageHistoryFetcher.revisionsPerPage,
                    direction: .older,
                    continueToken: requestParams.pagingInfo.continueKey,
                    rvContinueToken: requestParams.pagingInfo.rvContinueKey
                )
                success(HistoryFetchResults(page: page, pendingRevision: requestParams.lastRevisionFromPreviousCall))
            } catch {
                failure(error)
            }
        }
    }

    // MARK: Creation date

    public func fetchFirstRevision(for pageTitle: String, pageURL: URL, completion: @escaping (Result<WMFPageRevision, RequestError>) -> Void) {
        guard let project = WikimediaProject(siteURL: pageURL)?.wmfProject else {
            completion(.failure(.invalidParameters))
            return
        }

        Task {
            do {
                let revision = try await WMFPageHistoryDataController.shared.fetchFirstRevision(project: project, title: pageTitle)
                completion(.success(revision))
            } catch {
                completion(.failure(.unexpectedResponse))
            }
        }
    }

    // MARK: Edit counts

    public enum EditCountType: String {
        case editors
        case edits
        case minor
        case bot
        case anonymous
        case temporary
        case customLoggedIn
        case customUnregistered
    }

    private func editCountsURL(for editCountType: EditCountType, pageTitle: String, pageURL: URL, from fromRevisionID: Int? = nil , to toRevisionID: Int? = nil) -> URL? {
        guard let project = pageURL.wmf_site,
              project.host != nil,
        let title = pageTitle.percentEncodedPageTitleForPathComponents else {
            return nil
        }

        var pathComponents = ["v1", "page"]
        pathComponents.append(title)
        pathComponents.append(contentsOf: ["history", "counts"])
        pathComponents.append(editCountType.rawValue)
        let queryParameters: [String: String]?
        if let fromRevisionID = fromRevisionID, let toRevisionID = toRevisionID {
            queryParameters = ["from": String(fromRevisionID), "to": String(toRevisionID)]
        } else {
            queryParameters = nil
        }
        return configuration.mediaWikiRestAPIURLForURL(project, appending: pathComponents, queryParameters: queryParameters)
    }

    private struct EditCount: Decodable {
        let count: Int?
        let limit: Bool?
    }

    public func fetchEditCounts(_ editCountTypes: EditCountType..., for pageTitle: String, pageURL: URL, from fromRevisionID: Int? = nil , to toRevisionID: Int? = nil, completion: @escaping (Result<EditCountsGroupedByType, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            var editCountsGroupedByType = EditCountsGroupedByType()
            var mostRecentError: Error?
            
            // An API call with the custom types would actually fail. customLoggedIn and customUnregistered are inferred below (edits - anon - temporary, anon + temporary respectively)
            let editCountTypesMinusCustomTypes = editCountTypes.filter { $0 != .customLoggedIn && $0 != .customUnregistered }
            
            for editCountType in editCountTypesMinusCustomTypes {
                guard let url = self.editCountsURL(for: editCountType, pageTitle: pageTitle, pageURL: pageURL, from: fromRevisionID, to: toRevisionID) else {
                    continue
                }
                group.enter()
                self.session.jsonDecodableTask(with: url) { (editCount: EditCount?, response: URLResponse?, error: Error?) in
                    if let error = error {
                        mostRecentError = error
                        group.leave()
                        return
                    }
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        mostRecentError = RequestError.unexpectedResponse
                        group.leave()
                        return
                    }
                    guard let count = editCount?.count else {
                        group.leave()
                        return
                    }
                    editCountsGroupedByType[editCountType] = (count, editCount?.limit ?? false)
                    group.leave()
                }
            }
            group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                let typesContainsCustom = editCountTypes.contains {$0 == .customUnregistered || $0 == .customLoggedIn}
                if typesContainsCustom, let anonEdits = editCountsGroupedByType[.anonymous], !anonEdits.limit, let tempEdits = editCountsGroupedByType[.temporary], !tempEdits.limit {
                    
                    if editCountTypes.contains(.customLoggedIn),
                       let edits = editCountsGroupedByType[.edits], !edits.limit {
                        editCountsGroupedByType[.customLoggedIn] = (edits.count - anonEdits.count - tempEdits.count, false)
                    }
                    
                    editCountsGroupedByType[.customUnregistered] = (anonEdits.count + tempEdits.count, false)
                    
                }
                
                if editCountsGroupedByType.isEmpty, let mostRecentError = mostRecentError {
                    completion(.failure(mostRecentError))
                } else {
                    completion(.success(editCountsGroupedByType))
                }
            }
        }
    }

    // MARK: Edit metrics

    private struct EditMetrics: Decodable {
        let items: [Item]?

        struct Item: Decodable {
            let results: [Result]?

            struct Result: Decodable {
                let edits: Int?
            }
        }
    }

    public func fetchEditMetrics(for pageTitle: String, pageURL: URL, completion: @escaping (Result<[NSNumber], Error>) -> Void ) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let title = pageTitle.percentEncodedPageTitleForPathComponents,
                let project = pageURL.wmf_site?.host,
                let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()),
                let from = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()?.string(from: yearAgo),
                let to = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()?.string(from: Date())
            else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            let pathComponents = ["edits", "per-page", project, title, "all-editor-types", "monthly", from, to]
            let components =  self.configuration.metricsAPIURLComponents(appending: pathComponents)
            guard let url = components.url else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            self.session.jsonDecodableTask(with: url) { (editMetrics: EditMetrics?, response: URLResponse?, error: Error?) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                var allEdits = [NSNumber]()
                guard
                    let items = editMetrics?.items,
                    let firstItem = items.first,
                    let results = firstItem.results
                else {
                    completion(.failure(RequestError.noNewData))
                    return
                }
                for case let result in results {
                    guard let edits = result.edits else {
                        continue
                    }
                    allEdits.append(NSNumber(value: edits))
                }
                completion(.success(allEdits))
            }
        }
    }

}

private typealias RevisionsByDay = [Int: PageHistorySection]
private typealias PagingInfo = (continueKey: String?, rvContinueKey: String?, batchComplete: Bool)

/// One page of revision history, grouped by day.
final class HistoryFetchResults {
    fileprivate let pagingInfo: PagingInfo
    /// The last revision of the page. Its size difference is not known until the next page arrives.
    let lastRevision: WMFPageRevision?
    fileprivate let revisionsByDay: RevisionsByDay

    func getPageHistoryRequestParameters(_ articleURL: URL) -> PageHistoryRequestParameters {
        return PageHistoryRequestParameters(title: articleURL.wmf_title ?? "", pagingInfo: pagingInfo, lastRevisionFromPreviousCall: lastRevision)
    }

    func items() -> [PageHistorySection] {
        return self.revisionsByDay.keys.sorted(by: <).compactMap { self.revisionsByDay[$0] }
    }

    func batchComplete() -> Bool {
        return self.pagingInfo.batchComplete
    }

    /// Build the results from one API page.
    ///
    /// The pending revision from the previous page gets its size difference from the first revision of this page.
    /// This page holds back its own last revision in the same way, unless the batch is complete.
    fileprivate init(page: WMFPageRevisionsPage, pendingRevision: WMFPageRevision?) {
        var revisions = page.revisions

        if var pendingRevision, let first = revisions.first {
            pendingRevision.revisionSize = pendingRevision.articleSizeAtRevision - first.articleSizeAtRevision
            revisions.insert(pendingRevision, at: 0)
        }

        var lastRevision: WMFPageRevision?
        if let last = revisions.last, !page.batchComplete, last.parentID != 0 {
            lastRevision = revisions.removeLast()
        }

        var revisionsByDay = RevisionsByDay()
        for revision in revisions {
            HistoryFetchResults.update(revisionsByDay: &revisionsByDay, revision: revision)
        }

        self.pagingInfo = (page.continueToken, page.rvContinueToken, page.batchComplete)
        self.revisionsByDay = revisionsByDay
        self.lastRevision = lastRevision
    }
}

final class PageHistoryRequestParameters {
    fileprivate let pagingInfo: PagingInfo
    fileprivate let lastRevisionFromPreviousCall: WMFPageRevision?
    fileprivate let title: String

    fileprivate init(title: String, pagingInfo: PagingInfo, lastRevisionFromPreviousCall: WMFPageRevision?) {
        self.title = title
        self.pagingInfo = pagingInfo
        self.lastRevisionFromPreviousCall = lastRevisionFromPreviousCall
    }

    init(title: String) {
        self.title = title
        pagingInfo = (nil, nil, false)
        lastRevisionFromPreviousCall = nil
    }
}

extension HistoryFetchResults {
    fileprivate static func update(revisionsByDay: inout RevisionsByDay, revision: WMFPageRevision) {
        let distanceToToday = revision.daysFromToday()

        guard revision.user != nil else {
            return
        }

        guard let existingRevisionsOnCurrentDay = revisionsByDay[distanceToToday] else {
            guard let revisionDate = revision.revisionDate else {
                return
            }
            let sectionTitle = DateFormatter.wmf_long().string(from: revisionDate)
            let newSection = PageHistorySection(sectionTitle: sectionTitle, items: [revision])
            revisionsByDay[distanceToToday] = newSection
            return
        }

        let sectionTitle = existingRevisionsOnCurrentDay.sectionTitle
        let items = existingRevisionsOnCurrentDay.items + [revision]
        revisionsByDay[distanceToToday] = PageHistorySection(sectionTitle: sectionTitle, items: items)
    }
}
