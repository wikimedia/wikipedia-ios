import Foundation
import Mantle
import WMF

public typealias EditCountsGroupedByType = [PageHistoryFetcher.EditCountType: Int?]

public final class PageHistoryFetcher: WMFLegacyFetcher {
    @objc func fetchRevisionInfo(_ siteURL: URL, requestParams: PageHistoryRequestParameters, failure: @escaping WMFErrorHandler, success: @escaping (HistoryFetchResults) -> Void) -> Void {
        var params: [String: AnyObject] = [
            "action": "query" as AnyObject,
            "prop": "revisions" as AnyObject,
            "rvprop": "ids|timestamp|user|size|parsedcomment|flags" as AnyObject,
            "rvlimit": 51 as AnyObject,
            "rvdir": "older" as AnyObject,
            "titles": requestParams.title as AnyObject,
            "continue": requestParams.pagingInfo.continueKey as AnyObject? ?? "" as AnyObject,
            "format": "json" as AnyObject
            //,"rvdiffto": -1 //Add this to fake out "error" api response.
        ]
        
        if let rvContinueKey = requestParams.pagingInfo.rvContinueKey {
            params["rvcontinue"] = rvContinueKey as AnyObject?
        }
        
        //TODO: forcing wmflabs here for usertesting
        var siteUrlPathComponents = siteURL.pathComponents
        siteUrlPathComponents.removeAll(where: {$0 == "/"})
        guard let newSiteURL = configuration.mediaWikiAPIURForHost("en.wikipedia.beta.wmflabs.org", appending: siteUrlPathComponents).url else {
            return
        }
        
        performMediaWikiAPIGET(for: newSiteURL, withQueryParameters: params) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard let result = result, let results = self.parseSections(result) else {
                failure(RequestError.unexpectedResponse)
                return
            }
            results.tackOn(requestParams.lastRevisionFromPreviousCall)
            success(results)
        }
    }
    
    private func parseSections(_ responseDict: [String: Any]) -> HistoryFetchResults? {
        guard let query = responseDict["query"] as? [String: Any], let pages = query["pages"] as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return nil
        }
        
        var lastRevision: WMFPageHistoryRevision?
        var revisionsByDay = RevisionsByDay()
        for (_, value) in pages {
            let transformer = MTLJSONAdapter.arrayTransformer(withModelClass: WMFPageHistoryRevision.self)
            
            guard let val = value["revisions"], let revisions = transformer?.transformedValue(val) as? [WMFPageHistoryRevision] else {
                assertionFailure("couldn't parse page history revisions")
                return nil
            }
            
            revisionsByDay = parse(revisions: revisions, existingRevisions: revisionsByDay)
            
            if let earliestRevision = revisions.last, earliestRevision.parentID == 0 {
                earliestRevision.revisionSize = earliestRevision.articleSizeAtRevision
                HistoryFetchResults.update(revisionsByDay: &revisionsByDay, revision: earliestRevision)
            } else {
                lastRevision = revisions.last
            }
        }
        
        return HistoryFetchResults(pagingInfo: parsePagingInfo(responseDict), revisionsByDay: revisionsByDay, lastRevision: lastRevision)
    }
    
    private func parsePagingInfo(_ responseDict: [String: Any]) -> (continueKey: String?, rvContinueKey: String?, batchComplete: Bool) {
        var continueKey: String? = nil
        var rvContinueKey: String? = nil
        if let continueInfo = responseDict["continue"] as? [String: Any] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        let batchComplete = responseDict["batchcomplete"] != nil
        
        return (continueKey, rvContinueKey, batchComplete)
    }
    
    private typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
    private func parse(revisions: [WMFPageHistoryRevision], existingRevisions: RevisionsByDay) -> RevisionsByDay {
        return zip(revisions, revisions.dropFirst()).reduce(existingRevisions, { (revisionsByDay, itemPair: RevisionCurrentPrevious) -> RevisionsByDay in
            var revisionsByDay = revisionsByDay
            
            itemPair.current.revisionSize = itemPair.current.articleSizeAtRevision - itemPair.previous.articleSizeAtRevision
            HistoryFetchResults.update(revisionsByDay:&revisionsByDay, revision: itemPair.current)
            
            return revisionsByDay
        })
    }

    // MARK: Creation date

    public func fetchPageCreationDate(for pageTitle: String, pageURL: URL, completion: @escaping (Result<Date, RequestError>) -> Void) {
        let params: [String: AnyObject] = [
            "action": "query" as AnyObject,
            "prop": "revisions" as AnyObject,
            "rvlimit": 1 as AnyObject,
            "rvdir": "newer" as AnyObject,
            "titles": pageTitle as AnyObject,
            "format": "json" as AnyObject
        ]
        
        performMediaWikiAPIGET(for: pageURL, withQueryParameters: params) { (result, response, error) in
            guard let result = result, let results = self.parseSections(result) else {
                completion(.failure(.unexpectedResponse))
                return
            }
            guard let firstRevisionDate = results.lastRevision?.revisionDate else {
                completion(.failure(.unexpectedResponse))
                return
            }
            completion(.success(firstRevisionDate))
        }
    }

    // MARK: Edit counts

    public enum EditCountType: String {
        case editors
        case edits
        case minor
        case bot
        case anonymous
        case userEdits
    }

    private func editCountsURL(for editCountType: EditCountType, pageTitle: String, pageURL: URL) -> URL? {
        // TODO: Get project from pageURL
        var pathComponents = ["v1", "page"]
        pathComponents.append(pageTitle.wmf_denormalizedPageTitle())
        pathComponents.append(contentsOf: ["history", "counts"])
        pathComponents.append(editCountType.rawValue)
        let components = configuration.mediaWikiRestAPIURLForHost("en.wikipedia.beta.wmflabs.org", appending: pathComponents)
        return components.url
    }

    private struct EditCount: Decodable {
        let count: Int?
    }

    public func fetchEditCounts(_ editCountTypes: EditCountType..., for pageTitle: String, pageURL: URL, completion: @escaping (Result<EditCountsGroupedByType, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            var editCountsGroupedByType = EditCountsGroupedByType()
            var mostRecentError: Error?
            for editCountType in editCountTypes {
                guard let url = self.editCountsURL(for: editCountType, pageTitle: pageTitle, pageURL: pageURL) else {
                    continue
                }
                group.enter()
                self.session.jsonDecodableTask(with: url) { (editCount: EditCount?, response: URLResponse?, error: Error?) in
                    if let error = error {
                        mostRecentError = error
                    }
                    defer {
                        group.leave()
                    }
                    // TODO: Check for additional info in the response. If the count of minor edits is > 500k, the count will be set to 500k and the response will include additional information. 
                    editCountsGroupedByType[editCountType] = editCount?.count
                }
            }
            group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                if let edits = editCountsGroupedByType[.edits], let editsCount = edits, let anonEdits = editCountsGroupedByType[.anonymous], let anonEditsCount = anonEdits {
                    editCountsGroupedByType[.userEdits] = editsCount - anonEditsCount
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
                let title = pageTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                let project = pageURL.wmf_site?.host,
                let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()),
                let from = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()?.string(from: yearAgo),
                let to = DateFormatter.wmf_englishUTCNonDelimitedYearMonthDay()?.string(from: Date())
            else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            let pathComponents = ["metrics", "edits", "per-page", project, title, "all-editor-types", "monthly", from, to]
            let components =  self.configuration.wikimediaMobileAppsServicesAPIURLComponents(appending: pathComponents)
            guard let url = components.url else {
                completion(.failure(RequestError.invalidParameters))
                return
            }
            self.session.jsonDecodableTask(with: url) { (editMetrics: EditMetrics?, response: URLResponse?, error: Error?) in
                if let error = error {
                    completion(.failure(error))
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                var allEdits = [NSNumber]()
                defer {
                    completion(.success(allEdits))
                }
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
            }
        }
    }

}

private typealias RevisionsByDay = [Int: PageHistorySection]
private typealias PagingInfo = (continueKey: String?, rvContinueKey: String?, batchComplete: Bool)
open class HistoryFetchResults: NSObject {
    fileprivate let pagingInfo: PagingInfo
    fileprivate let lastRevision: WMFPageHistoryRevision?
    fileprivate var revisionsByDay: RevisionsByDay
    
    @objc open func getPageHistoryRequestParameters(_ articleURL: URL) -> PageHistoryRequestParameters {
        return PageHistoryRequestParameters(title: articleURL.wmf_title ?? "", pagingInfo: pagingInfo, lastRevisionFromPreviousCall: lastRevision)
    }
    
    @objc open func items() -> [PageHistorySection]  {
        return self.revisionsByDay.keys.sorted(by: <).compactMap() { self.revisionsByDay[$0] }
    }
    
    @objc open func batchComplete() -> Bool {
        return self.pagingInfo.batchComplete
    }
    
    fileprivate func tackOn(_ lastRevisionFromPreviousCall: WMFPageHistoryRevision?) {
        guard let previouslyParsedRevision = lastRevisionFromPreviousCall, let parentSize = items().first?.items.first?.articleSizeAtRevision else { return }
        previouslyParsedRevision.revisionSize = previouslyParsedRevision.articleSizeAtRevision - parentSize
        HistoryFetchResults.update(revisionsByDay: &revisionsByDay, revision: previouslyParsedRevision)
    }
    
    fileprivate init(pagingInfo: PagingInfo, revisionsByDay: RevisionsByDay, lastRevision: WMFPageHistoryRevision?) {
        self.pagingInfo = pagingInfo
        self.revisionsByDay = revisionsByDay
        self.lastRevision = lastRevision
    }
}

open class PageHistoryRequestParameters: NSObject {
    fileprivate let pagingInfo: PagingInfo
    fileprivate let lastRevisionFromPreviousCall: WMFPageHistoryRevision?
    fileprivate let title: String
    
    fileprivate init(title: String, pagingInfo: PagingInfo, lastRevisionFromPreviousCall: WMFPageHistoryRevision?) {
        self.title = title
        self.pagingInfo = pagingInfo
        self.lastRevisionFromPreviousCall = lastRevisionFromPreviousCall
    }
    //TODO: get rid of this when the VC is swift and we can use default values in the other init
    @objc public init(title: String) {
        self.title = title
        pagingInfo = (nil, nil, false)
        lastRevisionFromPreviousCall = nil
    }
}

extension HistoryFetchResults {
    fileprivate static func update(revisionsByDay: inout RevisionsByDay, revision: WMFPageHistoryRevision) {
        let distanceToToday = revision.daysFromToday()
        
        guard revision.user != nil else {
            return
        }
        
        if let existingRevisionsOnCurrentDay = revisionsByDay[distanceToToday] {
            let sectionTitle = existingRevisionsOnCurrentDay.sectionTitle
            let items = existingRevisionsOnCurrentDay.items + [revision]
            revisionsByDay[distanceToToday] = PageHistorySection(sectionTitle: sectionTitle, items: items)
        } else {
            if let revisionDate = revision.revisionDate {
                var title: String?
                let getSectionTitle = {
                    title = DateFormatter.wmf_long().string(from: revisionDate)
                }
                if Thread.isMainThread {
                    getSectionTitle()
                } else {
                    DispatchQueue.main.sync(execute: getSectionTitle)
                }
                guard let sectionTitle = title else { return }
                let newSection = PageHistorySection(sectionTitle: sectionTitle, items: [revision])
                revisionsByDay[distanceToToday] = newSection
            }
        }
    }
}
