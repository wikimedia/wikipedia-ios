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

    public func fetchRevisionInfo(title: MWKTitle, requestParams: PageHistoryRequestParameters) -> AnyPromise {
        return AnyPromise(resolverBlock: { [weak self] (resolve) in
            guard let strongSelf = self else { return }
            strongSelf.operationManager.wmf_GETWithSite(title.site,
                                                        parameters: requestParams,
                                                        retry: nil,
                                                        success: { (operation, responseObject) in
                                                        MWNetworkActivityIndicatorManager.sharedManager().pop()
                                                            resolve(responseObject)
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
    public let items: [PageHistorySection]
    
    public func getPageHistoryRequestParameters(title: String) -> PageHistoryRequestParameters {
        return PageHistoryRequestParameters(title: title, continueKey: continueKey, rvContinueKey: rvContinueKey)
    }
    
    private init?(responseDict: [String: AnyObject], items: [PageHistorySection]) {
        if let continueInfo = responseDict["continue"] as? [String: AnyObject] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        else {
            continueKey = nil
            rvContinueKey = nil
        }
        
        batchComplete = responseDict["batchcomplete"] != nil
        self.items = items
    }
}

public class PageHistoryRequestParameters: NSObject {
    private let title: String
    private let continueKey: String?
    private let rvContinueKey: String?
    
    public init(title: String, continueKey: String?, rvContinueKey: String?) {
        self.title = title
        self.continueKey = continueKey
        self.rvContinueKey = rvContinueKey
    }
    //TODO: get rid of this when the VC is swift and we can use default values in the other init
    public init(title: String) {
        self.title = title
        continueKey = nil
        rvContinueKey = nil
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

public class PageHistoryResponseSerializer: WMFApiJsonResponseSerializer {
    public override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {
        guard let responseDict = super.responseObjectForResponse(response, data: data, error: error) as? [String: AnyObject] else { return nil }
        return parseSections(responseDict)
    }

    //Mark: Data Parsing
    private typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
    private typealias RevisionsByDay = [Int: PageHistorySection]
    
    //Mark: Paging
    private var lastRevisionFromPreviousCall: WMFPageHistoryRevision?
    
    private func parseSections(responseDict: [String: AnyObject]) -> HistoryFetchResults? {
        guard let pages = responseDict["query"]?["pages"] as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return nil
        }
        
        var revisionsByDay = RevisionsByDay()
        for (_, value) in pages {
            let transformer = MTLJSONAdapter.arrayTransformerWithModelClass(WMFPageHistoryRevision.self)
            
            guard var revisions = transformer.transformedValue(value["revisions"]) as? [WMFPageHistoryRevision] else {
                assertionFailure("couldn't parse page history revisions")
                return nil
            }
            if let leftoverRevisionFromPreviousCall = lastRevisionFromPreviousCall {
                revisions.insert(leftoverRevisionFromPreviousCall, atIndex: 0)
            }
            
            revisionsByDay = parse(revisions: revisions, existingRevisions: revisionsByDay)
            
            if let earliestRevision = revisions.last where earliestRevision.parentID == 0 {
                earliestRevision.revisionSize = earliestRevision.articleSizeAtRevision
                update(revisionsByDay: &revisionsByDay, revision: earliestRevision)
            } else {
                lastRevisionFromPreviousCall = revisions.last
            }
        }
        
        let items = revisionsByDay.keys.sort(<).flatMap() { revisionsByDay[$0] }
        
        return HistoryFetchResults(responseDict: responseDict, items: items)
    }
    
    private func parse(revisions revisions: [WMFPageHistoryRevision], existingRevisions: RevisionsByDay) -> RevisionsByDay {
        return zip(revisions, revisions.dropFirst()).reduce(existingRevisions, combine: { (revisionsByDay, itemPair: RevisionCurrentPrevious) -> RevisionsByDay in
            var revisionsByDay = revisionsByDay
            
            itemPair.current.revisionSize = itemPair.current.articleSizeAtRevision - itemPair.previous.articleSizeAtRevision
            update(revisionsByDay:&revisionsByDay, revision: itemPair.current)
            
            return revisionsByDay
        })
    }
    
    private func update(inout revisionsByDay revisionsByDay: RevisionsByDay, revision: WMFPageHistoryRevision) {
        let distanceToToday = revision.daysFromToday()
        
        if let existingRevisionsOnCurrentDay = revisionsByDay[distanceToToday] {
            let sectionTitle = existingRevisionsOnCurrentDay.sectionTitle
            let items = existingRevisionsOnCurrentDay.items + [revision]
            revisionsByDay[distanceToToday] = PageHistorySection(sectionTitle: sectionTitle, items: items)
        } else {
            if let revisionDate = revision.revisionDate {
                let sectionTitle = NSDateFormatter.wmf_longDateFormatter().stringFromDate(revisionDate)
                let newSection = PageHistorySection(sectionTitle: sectionTitle, items: [revision])
                revisionsByDay[distanceToToday] = newSection
            }
        }
    }
}