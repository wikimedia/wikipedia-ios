import Foundation
import AFNetworking
import Mantle


class PageHistoryFetcher: NSObject {
    private let operationManager: AFHTTPSessionManager = {
        let manager = AFHTTPSessionManager.wmf_createDefaultManager()
        manager.responseSerializer = WMFApiJsonResponseSerializer()
        return manager
    }()

    func fetchRevisionInfo(title: MWKTitle) -> AnyPromise {
        return AnyPromise(resolverBlock: { [weak self] (resolve) in
            guard let strongSelf = self else { return }
            strongSelf.operationManager.wmf_GETWithSite(title.site,
                                                        parameters: strongSelf.getParams(title),
                                                        retry: nil,
                                                        success: { (operation, responseObject) in
                                                            MWNetworkActivityIndicatorManager.sharedManager().pop()
                                                            strongSelf.updatePagingState(responseObject)
                                                            resolve(strongSelf.parseSections(responseObject))
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
    
    private func updatePagingState(responseObject: AnyObject) {
        if let continueInfo = responseObject["continue"] as? [String: AnyObject] {
            continueKey = continueInfo["continue"] as? String
            rvContinueKey = continueInfo["rvcontinue"] as? String
        }
        if let _ = responseObject["batchComplete"] {
            batchComplete = true
        }
    }
    
    //Mark: Data Parsing
    private typealias RevisionCurrentPrevious = (current: WMFPageHistoryRevision, previous: WMFPageHistoryRevision)
    private typealias RevisionsByDay = [Int: WMFPageHistorySection]

    private func parseSections(rawResponse: AnyObject) -> [WMFPageHistorySection] {
        guard let pages = rawResponse["query"]??["pages"] as? [String: AnyObject] else {
            assertionFailure("couldn't parse page history response")
            return []
        }
        
        var revisionsByDay = RevisionsByDay()
        for (_, value) in pages {
            let transformer = MTLJSONAdapter.arrayTransformerWithModelClass(WMFPageHistoryRevision.self)
            
            guard let revisions = transformer.transformedValue(value["revisions"]) as? [WMFPageHistoryRevision] else { return [] }
            let reverseRevisions = Array(revisions.reverse())
            
            revisionsByDay = parse(revisions: reverseRevisions, existingRevisions: revisionsByDay)
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
            existingRevisionsOnCurrentDay.items?.insertObject(revision, atIndex: 0)
        } else {
            let newSection = WMFPageHistorySection()
            newSection.items = [revision]
            if let revisionDate = revision.revisionDate {
                newSection.sectionTitle = NSDateFormatter.wmf_longDateFormatter().stringFromDate(revisionDate)
            }
            revisionsByDay[distanceToToday] = newSection
        }
    }
    
    //Mark: API Parameters
    private func getParams(title: MWKTitle) -> [String: AnyObject] {
        var params: [String: AnyObject] = [
        "action": "query",
        "prop": "revisions",
        "rvprop": "ids|timestamp|user|size|parsedcomment",
        "rvlimit": 51,
        "rvdir": "older",
        "titles": title.text,
        "continue": continueKey ?? "",
        "format": "json"
        //,"rvdiffto": -1 //Add this to fake out "error" api response.
        ]
        
        if let rvContinueKey = self.rvContinueKey {
            params["rvcontinue"] = rvContinueKey
        }
        
        return params
    }
}