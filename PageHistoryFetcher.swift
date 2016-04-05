import Foundation
import AFNetworking
import Mantle


public class PageHistoryFetcher: NSObject {
    private let operationManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager.wmf_createDefaultManager()
        manager.responseSerializer = WMFApiJsonResponseSerializer()
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
                                                            guard let strongSelf = self, responseDict = responseObject as? [String: AnyObject] else { return }
                                                            MWNetworkActivityIndicatorManager.sharedManager().pop()
                                                            strongSelf.updatePagingState(responseDict)
                                                            resolve(strongSelf.parseSections(responseDict))
                                                            },
                                                        failure: { (operation, error) in
                                                                MWNetworkActivityIndicatorManager.sharedManager().pop()
                                                                resolve(error)
                                                        })
        })
    }
    
    //Mark: Paging
    private var continueKey: String?
    private var rvContinueKey: String?
    var batchComplete: Bool = false
    private var lastRevisionFromPreviousCall: WMFPageHistoryRevision?

    private func updatePagingState(responseDict: [String: AnyObject]) {
        if let continueInfo = responseDict["continue"] as? [String: AnyObject] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        if responseDict["batchcomplete"] != nil {
            batchComplete = true
        }
    }
    
    //Mark: Data Parsing
    private typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
    private typealias RevisionsByDay = [Int: PageHistorySection]

    private func parseSections(responseDict: [String: AnyObject]) -> [PageHistorySection] {
        guard let pages = responseDict["query"]?["pages"] as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return []
        }
        
        var revisionsByDay = RevisionsByDay()
        for (_, value) in pages {
            let transformer = MTLJSONAdapter.arrayTransformerWithModelClass(WMFPageHistoryRevision.self)
            
            guard var revisions = transformer.transformedValue(value["revisions"]) as? [WMFPageHistoryRevision] else {
                assertionFailure("couldn't parse page history revisions")
                return []
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
        
        return revisionsByDay.keys.sort(<).flatMap() { revisionsByDay[$0] }
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

public class PageHistoryRequestParameters: NSObject {
    let title: String
    var continueKey: String?
    var rvContinueKey: String?
    
    init(title: String) {
        self.title = title
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
    
    func serializedParams(requestParameters: PageHistoryRequestParameters) -> [String: AnyObject] {
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