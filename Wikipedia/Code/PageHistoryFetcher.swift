import Foundation
import AFNetworking
import Mantle
import WMF

open class PageHistoryFetcher: NSObject {
    fileprivate let operationManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager.wmf_createDefault()
        manager.responseSerializer = PageHistoryResponseSerializer()
        manager.requestSerializer = PageHistoryRequestSerializer()
        return manager
    }()

    @objc open func fetchRevisionInfo(_ siteURL: URL, requestParams: PageHistoryRequestParameters, failure: @escaping WMFErrorHandler, success: @escaping (HistoryFetchResults) -> Void) -> Void {
        operationManager.wmf_GETAndRetry(with: siteURL,
                                                parameters: requestParams,
                                                retry: nil,
                                                success: { (operation, responseObject) in
                                                    MWNetworkActivityIndicatorManager.shared().pop()
                                                    guard let results = responseObject as? HistoryFetchResults else { return }
                                                    results.tackOn(requestParams.lastRevisionFromPreviousCall)
                                                    success(results)
            },
                                                failure: { (operation, error) in
                                                    MWNetworkActivityIndicatorManager.shared().pop()
                                                    guard let error = error else {
                                                        failure(NSError(domain: "", code: 0, userInfo: nil))
                                                        return
                                                    }
                                                    failure(error)
        })

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

open class PageHistoryRequestSerializer: AFHTTPRequestSerializer {
    open override func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        guard let pageHistoryParameters = parameters as? PageHistoryRequestParameters else {
            assertionFailure("pagehistoryfetcher has incorrect parameter type")
            return nil
        }
        return super.request(bySerializingRequest: request, withParameters: serializedParams(pageHistoryParameters), error: error)
    }
    
    fileprivate func serializedParams(_ requestParameters: PageHistoryRequestParameters) -> [String: AnyObject] {
        var params: [String: AnyObject] = [
            "action": "query" as AnyObject,
            "prop": "revisions" as AnyObject,
            "rvprop": "ids|timestamp|user|size|parsedcomment" as AnyObject,
            "rvlimit": 51 as AnyObject,
            "rvdir": "older" as AnyObject,
            "titles": requestParameters.title as AnyObject,
            "continue": requestParameters.pagingInfo.continueKey as AnyObject? ?? "" as AnyObject,
            "format": "json" as AnyObject
            //,"rvdiffto": -1 //Add this to fake out "error" api response.
        ]
        
        if let rvContinueKey = requestParameters.pagingInfo.rvContinueKey {
            params["rvcontinue"] = rvContinueKey as AnyObject?
        }
        
        return params
    }
}

open class PageHistoryResponseSerializer: WMFApiJsonResponseSerializer {
    open override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        guard let responseDict = super.responseObject(for: response, data: data, error: error) as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return nil
        }
        return parseSections(responseDict)
    }
    
    fileprivate func parseSections(_ responseDict: [String: AnyObject]) -> HistoryFetchResults? {
        guard let pages = responseDict["query"]?["pages"] as? [String: AnyObject] else {
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
    
    fileprivate func parsePagingInfo(_ responseDict: [String: AnyObject]) -> (continueKey: String?, rvContinueKey: String?, batchComplete: Bool) {
        var continueKey: String? = nil
        var rvContinueKey: String? = nil
        if let continueInfo = responseDict["continue"] as? [String: AnyObject] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        let batchComplete = responseDict["batchcomplete"] != nil
        
        return (continueKey, rvContinueKey, batchComplete)
    }
    
    fileprivate typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
    fileprivate func parse(revisions: [WMFPageHistoryRevision], existingRevisions: RevisionsByDay) -> RevisionsByDay {
        return zip(revisions, revisions.dropFirst()).reduce(existingRevisions, { (revisionsByDay, itemPair: RevisionCurrentPrevious) -> RevisionsByDay in
            var revisionsByDay = revisionsByDay
            
            itemPair.current.revisionSize = itemPair.current.articleSizeAtRevision - itemPair.previous.articleSizeAtRevision
            HistoryFetchResults.update(revisionsByDay:&revisionsByDay, revision: itemPair.current)
            
            return revisionsByDay
        })
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
