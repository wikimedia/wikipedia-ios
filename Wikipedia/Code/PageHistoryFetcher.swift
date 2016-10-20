import Foundation
import AFNetworking
import Mantle

public class PageHistoryFetcher: NSObject {
    private let operationManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager.wmf_createDefaultManager()
        manager.responseSerializer = PageHistoryResponseSerializer()
        manager.requestSerializer = PageHistoryRequestSerializer()
        return manager
    }()

    public func fetchRevisionInfo(siteURL: NSURL, requestParams: PageHistoryRequestParameters) -> AnyPromise {
        return AnyPromise(resolverBlock: { [weak self] (resolve) in
            guard let strongSelf = self else { return }
            strongSelf.operationManager.wmf_GETAndRetryWithURL(siteURL,
                                                        parameters: requestParams,
                                                        retry: nil,
                                                        success: { (operation, responseObject) in
                                                        MWNetworkActivityIndicatorManager.sharedManager().pop()
                                                            guard let results = responseObject as? HistoryFetchResults else { return }
                                                            results.tackOn(requestParams.lastRevisionFromPreviousCall)
                                                            resolve(results)
                                                            },
                                                        failure: { (operation, error) in
                                                                MWNetworkActivityIndicatorManager.sharedManager().pop()
                                                                resolve(error)
                                                        })
        })
    }
}

private typealias RevisionsByDay = [Int: PageHistorySection]
private typealias PagingInfo = (continueKey: String?, rvContinueKey: String?, batchComplete: Bool)
public class HistoryFetchResults: NSObject {
    private let pagingInfo: PagingInfo
    private let lastRevision: WMFPageHistoryRevision?
    private var revisionsByDay: RevisionsByDay
    
    public func getPageHistoryRequestParameters(articleURL: NSURL) -> PageHistoryRequestParameters {
        return PageHistoryRequestParameters(title: articleURL.wmf_title ?? "", pagingInfo: pagingInfo, lastRevisionFromPreviousCall: lastRevision)
    }
    
    public func items() -> [PageHistorySection]  {
        return self.revisionsByDay.keys.sort(<).flatMap() { self.revisionsByDay[$0] }
    }
    
    public func batchComplete() -> Bool {
        return self.pagingInfo.batchComplete
    }
    
    private func tackOn(lastRevisionFromPreviousCall: WMFPageHistoryRevision?) {
        guard let previouslyParsedRevision = lastRevisionFromPreviousCall, let parentSize = items().first?.items.first?.articleSizeAtRevision else { return }
        previouslyParsedRevision.revisionSize = previouslyParsedRevision.articleSizeAtRevision - parentSize
        HistoryFetchResults.update(revisionsByDay: &revisionsByDay, revision: previouslyParsedRevision)
    }
    
    private init(pagingInfo: PagingInfo, revisionsByDay: RevisionsByDay, lastRevision: WMFPageHistoryRevision?) {
        self.pagingInfo = pagingInfo
        self.revisionsByDay = revisionsByDay
        self.lastRevision = lastRevision
    }
}

public class PageHistoryRequestParameters: NSObject {
    private let pagingInfo: PagingInfo
    private let lastRevisionFromPreviousCall: WMFPageHistoryRevision?
    private let title: String
    
    private init(title: String, pagingInfo: PagingInfo, lastRevisionFromPreviousCall: WMFPageHistoryRevision?) {
        self.title = title
        self.pagingInfo = pagingInfo
        self.lastRevisionFromPreviousCall = lastRevisionFromPreviousCall
    }
    //TODO: get rid of this when the VC is swift and we can use default values in the other init
    public init(title: String) {
        self.title = title
        pagingInfo = (nil, nil, false)
        lastRevisionFromPreviousCall = nil
    }
}

public class PageHistoryRequestSerializer: AFHTTPRequestSerializer {
    public override func requestBySerializingRequest(request: NSURLRequest, withParameters parameters: AnyObject?, error: NSErrorPointer) -> NSURLRequest? {
        guard let pageHistoryParameters = parameters as? PageHistoryRequestParameters else {
            assertionFailure("pagehistoryfetcher has incorrect parameter type")
            return nil
        }
        return super.requestBySerializingRequest(request, withParameters: serializedParams(pageHistoryParameters), error: error)
    }
    
    private func serializedParams(requestParameters: PageHistoryRequestParameters) -> [String: AnyObject] {
        var params: [String: AnyObject] = [
            "action": "query",
            "prop": "revisions",
            "rvprop": "ids|timestamp|user|size|parsedcomment",
            "rvlimit": 51,
            "rvdir": "older",
            "titles": requestParameters.title,
            "continue": requestParameters.pagingInfo.continueKey ?? "",
            "format": "json"
            //,"rvdiffto": -1 //Add this to fake out "error" api response.
        ]
        
        if let rvContinueKey = requestParameters.pagingInfo.rvContinueKey {
            params["rvcontinue"] = rvContinueKey
        }
        
        return params
    }
}

public class PageHistoryResponseSerializer: WMFApiJsonResponseSerializer {
    public override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {
        guard let responseDict = super.responseObjectForResponse(response, data: data, error: error) as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return nil
        }
        return parseSections(responseDict)
    }
    
    private func parseSections(responseDict: [String: AnyObject]) -> HistoryFetchResults? {
        guard let pages = responseDict["query"]?["pages"] as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return nil
        }
        
        var lastRevision: WMFPageHistoryRevision?
        var revisionsByDay = RevisionsByDay()
        for (_, value) in pages {
            let transformer = MTLJSONAdapter.arrayTransformerWithModelClass(WMFPageHistoryRevision.self)
            
            guard let revisions = transformer.transformedValue(value["revisions"]) as? [WMFPageHistoryRevision] else {
                assertionFailure("couldn't parse page history revisions")
                return nil
            }
            
            revisionsByDay = parse(revisions: revisions, existingRevisions: revisionsByDay)
            
            if let earliestRevision = revisions.last where earliestRevision.parentID == 0 {
                earliestRevision.revisionSize = earliestRevision.articleSizeAtRevision
                HistoryFetchResults.update(revisionsByDay: &revisionsByDay, revision: earliestRevision)
            } else {
                lastRevision = revisions.last
            }
        }
        
        return HistoryFetchResults(pagingInfo: parsePagingInfo(responseDict), revisionsByDay: revisionsByDay, lastRevision: lastRevision)
    }
    
    private func parsePagingInfo(responseDict: [String: AnyObject]) -> (continueKey: String?, rvContinueKey: String?, batchComplete: Bool) {
        var continueKey: String? = nil
        var rvContinueKey: String? = nil
        if let continueInfo = responseDict["continue"] as? [String: AnyObject] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        let batchComplete = responseDict["batchcomplete"] != nil
        
        return (continueKey, rvContinueKey, batchComplete)
    }
    
    private typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
    private func parse(revisions revisions: [WMFPageHistoryRevision], existingRevisions: RevisionsByDay) -> RevisionsByDay {
        return zip(revisions, revisions.dropFirst()).reduce(existingRevisions, combine: { (revisionsByDay, itemPair: RevisionCurrentPrevious) -> RevisionsByDay in
            var revisionsByDay = revisionsByDay
            
            itemPair.current.revisionSize = itemPair.current.articleSizeAtRevision - itemPair.previous.articleSizeAtRevision
            HistoryFetchResults.update(revisionsByDay:&revisionsByDay, revision: itemPair.current)
            
            return revisionsByDay
        })
    }
}

extension HistoryFetchResults {
    private static func update(inout revisionsByDay revisionsByDay: RevisionsByDay, revision: WMFPageHistoryRevision) {
        let distanceToToday = revision.daysFromToday()
        
        if let existingRevisionsOnCurrentDay = revisionsByDay[distanceToToday] {
            let sectionTitle = existingRevisionsOnCurrentDay.sectionTitle
            let items = existingRevisionsOnCurrentDay.items + [revision]
            revisionsByDay[distanceToToday] = PageHistorySection(sectionTitle: sectionTitle, items: items)
        } else {
            if let revisionDate = revision.revisionDate {
                var title: String?
                let getSectionTitle = {
                    title = NSDateFormatter.wmf_longDateFormatter().stringFromDate(revisionDate)
                }
                if NSThread.isMainThread() {
                    getSectionTitle()
                } else {
                    dispatch_sync(dispatch_get_main_queue(), getSectionTitle)
                }
                guard let sectionTitle = title else { return }
                let newSection = PageHistorySection(sectionTitle: sectionTitle, items: [revision])
                revisionsByDay[distanceToToday] = newSection
            }
        }
    }
}
