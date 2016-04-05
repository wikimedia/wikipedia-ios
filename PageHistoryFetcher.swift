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

    public func fetchRevisionInfo(site: MWKSite, requestParams: PageHistoryRequestParameters) -> AnyPromise {
        return AnyPromise(resolverBlock: { [weak self] (resolve) in
            guard let strongSelf = self else { return }
            strongSelf.operationManager.wmf_GETWithSite(site,
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

public class HistoryFetchResults: NSObject {
    private let continueKey: String?
    private let rvContinueKey: String?
    public let batchComplete: Bool
    private let lastRevision: WMFPageHistoryRevision?
    private var revisionsByDay: RevisionsByDay
    
    public func getPageHistoryRequestParameters(title: String) -> PageHistoryRequestParameters {
        return PageHistoryRequestParameters(title: title, continueKey: continueKey, rvContinueKey: rvContinueKey, lastRevisionFromPreviousCall: lastRevision)
    }
    
    public func items() -> [PageHistorySection]  {
        return self.revisionsByDay.keys.sort(<).flatMap() { self.revisionsByDay[$0] }
    }
    
    private func tackOn(lastRevisionFromPreviousCall: WMFPageHistoryRevision?) {
        guard let previouslyParsedRevision = lastRevisionFromPreviousCall, parentSize = items().first?.items.first?.articleSizeAtRevision else { return }
        previouslyParsedRevision.revisionSize = previouslyParsedRevision.articleSizeAtRevision - parentSize
        update(revisionsByDay: &revisionsByDay, revision: previouslyParsedRevision)
    }
    
    private init(continueKey: String?, rvContinueKey: String?, batchComplete: Bool,  revisionsByDay: RevisionsByDay, lastRevision: WMFPageHistoryRevision?) {
        self.continueKey = continueKey
        self.rvContinueKey = rvContinueKey
        self.batchComplete = batchComplete
        self.revisionsByDay = revisionsByDay
        self.lastRevision = lastRevision
    }
}

public class PageHistoryRequestParameters: NSObject {
    private let title: String
    private let continueKey: String?
    private let rvContinueKey: String?
    private let lastRevisionFromPreviousCall: WMFPageHistoryRevision?

    public init(title: String, continueKey: String?, rvContinueKey: String?, lastRevisionFromPreviousCall: WMFPageHistoryRevision?) {
        self.title = title
        self.continueKey = continueKey
        self.rvContinueKey = rvContinueKey
        self.lastRevisionFromPreviousCall = lastRevisionFromPreviousCall
    }
    //TODO: get rid of this when the VC is swift and we can use default values in the other init
    public init(title: String) {
        self.title = title
        continueKey = nil
        rvContinueKey = nil
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
            "continue": requestParameters.continueKey ?? "",
            "format": "json"
            //,"rvdiffto": -1 //Add this to fake out "error" api response.
        ]
        
        if let rvContinueKey = requestParameters.rvContinueKey {
            params["rvcontinue"] = rvContinueKey
        }
        
        return params
    }
}

private typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
private typealias RevisionsByDay = [Int: PageHistorySection]

public class PageHistoryResponseSerializer: WMFApiJsonResponseSerializer {
    public override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {
        guard let responseDict = super.responseObjectForResponse(response, data: data, error: error) as? [String: AnyObject] else { return nil }
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
                update(revisionsByDay: &revisionsByDay, revision: earliestRevision)
            } else {
                lastRevision = revisions.last
            }
        }
        
        var continueKey: String? = nil
        var rvContinueKey: String? = nil
        if let continueInfo = responseDict["continue"] as? [String: AnyObject] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        let batchComplete = responseDict["batchcomplete"] != nil
        
        return HistoryFetchResults(continueKey: continueKey, rvContinueKey: rvContinueKey, batchComplete: batchComplete, revisionsByDay: revisionsByDay, lastRevision: lastRevision)
    }
    
    private func parse(revisions revisions: [WMFPageHistoryRevision], existingRevisions: RevisionsByDay) -> RevisionsByDay {
        return zip(revisions, revisions.dropFirst()).reduce(existingRevisions, combine: { (revisionsByDay, itemPair: RevisionCurrentPrevious) -> RevisionsByDay in
            var revisionsByDay = revisionsByDay
            
            itemPair.current.revisionSize = itemPair.current.articleSizeAtRevision - itemPair.previous.articleSizeAtRevision
            update(revisionsByDay:&revisionsByDay, revision: itemPair.current)
            
            return revisionsByDay
        })
    }
}

private func update(inout revisionsByDay revisionsByDay: RevisionsByDay, revision: WMFPageHistoryRevision) {
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
