
import Foundation

enum DiffError: Error {
    case generateUrlFailure
    case missingDiffResponseFailure
    case missingUrlResponseFailure
    case fetchRevisionIDFailure
    case noPreviousRevisionID
    case unrecognizedHardcodedIdsForIntermediateCounts
}

class DiffController {
    
    let diffFetcher: DiffFetcher
    let revisionFetcher: WMFArticleRevisionFetcher
    let globalUserInfoFetcher: GlobalUserInfoFetcher
    let articleTitle: String
    let siteURL: URL
    let type: DiffContainerViewModel.DiffType
    
    init(siteURL: URL, articleTitle: String, diffFetcher: DiffFetcher = DiffFetcher(), revisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), globalUserInfoFetcher: GlobalUserInfoFetcher = GlobalUserInfoFetcher(), type: DiffContainerViewModel.DiffType) {
        self.diffFetcher = diffFetcher
        self.revisionFetcher = revisionFetcher
        self.globalUserInfoFetcher = globalUserInfoFetcher
        self.articleTitle = articleTitle
        self.siteURL = siteURL
        self.type = type
    }
    
    func fetchIntermediateCounts(fromRevisionId: Int, toRevisionId: Int, completion: @escaping ((Result<(revision: Int, user: Int), Error>) -> Void)) {
        
        //tonitodo: intermediate counts endpoint when ready
        DispatchQueue.global(qos: .userInitiated).async {
            
            if fromRevisionId == 392751 && toRevisionId == 399777 {
                completion(.success((revision: 60, user: 12)))
            }
            
            completion(.failure(DiffError.unrecognizedHardcodedIdsForIntermediateCounts))
        }
    }
    
    func fetchEditCount(guiUser: String, siteURL: URL, completion: @escaping ((Result<Int, Error>) -> Void)) {
        globalUserInfoFetcher.fetchEditCount(guiUser: guiUser, siteURL: siteURL, completion: completion)
    }
    
    func fetchDiff(fromRevisionId: Int?, toRevisionId: Int, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {
        
        if let fromRevisionId = fromRevisionId {
            fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, theme: theme, traitCollection: traitCollection, completion: completion)
            return
        }
        
        fetchSingleNextRevision(toRevisionId: toRevisionId) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let fromRevisionId):
                self?.fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, theme: theme, traitCollection: traitCollection, completion: completion)
            }
        }
    }
    
    private func fetchSingleNextRevision(toRevisionId: Int, completion: @escaping ((Result<Int, Error>) -> Void)) {
        
        //TODO: forcing wmflabs here for usertesting
        
        guard let articleTitle = (articleTitle as NSString).wmf_normalizedPageTitle(),
            let articleURL = siteURL.wmf_URL(withPath: "/wiki/\(articleTitle)", isMobile: true)else {
            return
        }
        
        revisionFetcher.fetchLatestRevisions(forArticleURL: articleURL, articleTitle: articleTitle, resultLimit: 2, startingWithRevision: NSNumber(value: toRevisionId), endingWithRevision: nil, failure: { (error) in
            completion(.failure(error))
        }) { (result) in
            
            let queryResults = (result as? [WMFRevisionQueryResults])?.first ?? (result as? WMFRevisionQueryResults)
            
            guard let lastRevisionId = queryResults?.revisions.last?.revisionId.intValue else {
                completion(.failure(DiffError.fetchRevisionIDFailure))
                return
            }
            
            if lastRevisionId == toRevisionId {
                completion(.failure(DiffError.noPreviousRevisionID))
                return
            }
            
            completion(.success(lastRevisionId))
            
        }
    }
    
    private func fetchDiff(fromRevisionId: Int, toRevisionId: Int, theme: Theme, traitCollection: UITraitCollection, completion: @escaping ((Result<[DiffListGroupViewModel], Error>) -> Void)) {
        
        diffFetcher.fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId) { [weak self] (result) in
            
            guard let self = self else { return }
            
            switch result {
            case .success(var diffResponse):
                
                let groupedMoveIndexes = self.groupedIndexesOfMoveItems(from: diffResponse)
                switch self.type {
                case .single:
                    self.hardCodeSectionInfo(into: &diffResponse, toRevisionID: toRevisionId)
                    self.populateDeletedMovedSectionTitles(into: &diffResponse)
                    let response: [DiffListGroupViewModel] = self.viewModelsForSingle(from: diffResponse, theme: theme, traitCollection: traitCollection, type: self.type, groupedMoveIndexes: groupedMoveIndexes)
                    
                    completion(.success(response))
                case .compare:
                    let response: [DiffListGroupViewModel] = self.viewModelsForCompare(from: diffResponse, theme: theme, traitCollection: traitCollection, type: self.type, groupedMoveIndexes: groupedMoveIndexes)
                    completion(.success(response))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func groupedIndexesOfMoveItems(from response: DiffResponse) -> [String: Int] {
        let movedItems = response.diff.filter { $0.type == .moveSource || $0.type == .moveDestination }
        
        var indexCounter = 0
        var result: [String: Int] = [:]
        
        for item in movedItems {
            
            if let id = item.moveInfo?.id,
                let linkId = item.moveInfo?.linkId {

                if result[id] == nil {
                    if let existingIndex = result[linkId] {
                        result[id] = existingIndex
                    } else {
                        result[id] = indexCounter
                        indexCounter += 1
                    }
                }
            }
        }
        
        return result
    }
    
    private func hardCodeSectionInfo(into response: inout DiffResponse, toRevisionID: Int) {
        if toRevisionID == 399777 {
            response.sectionInfo = [
                SectionInfo(title: "==Taxonomy==", location: 1),
                SectionInfo(title: "==Biology==", location: 2),
                SectionInfo(title: "===Senses===", location: 3)
//                SectionInfo(title: "====Vision====", location: 4),
//                SectionInfo(title: "===='''Hearing'''====", location: 5),
//                SectionInfo(title: "====Smell====", location: 6),
//                SectionInfo(title: "===Physical characteristics===", location: 7),
//                SectionInfo(title: "====Coat====", location: 8),
//                SectionInfo(title: "===Types and breeds===", location: 9),
//                SectionInfo(title: "== See also ==", location: 10),
//                SectionInfo(title: "==See also (as well)==", location: 11),
//                SectionInfo(title: "==References==", location: 12),
//                SectionInfo(title: "==Bibliography==", location: 13),
//                SectionInfo(title: "==Further reading==", location: 14),
//                SectionInfo(title: "== External links ==", location: 15),
            ]
            
            var newItems: [DiffItem] = []
            for (diffIndex, var item) in response.diff.enumerated() {
                switch diffIndex {
                case 0, 1, 4, 5: item.sectionInfoIndex = 0
                case 6, 7, 8, 9, 10: item.sectionInfoIndex = 1
                case 11: item.sectionInfoIndex = 2
                default:
                    break
                }
                
                newItems.append(item)
            }
            
            response.diff = newItems
        } else if toRevisionID == 392751 {
            //only intro (before any sections) changed on this one so not hardcoding any section info
        }
    }
    
    private func populateDeletedMovedSectionTitles(into response: inout DiffResponse) {
        
        //We have some unknown sections from the endpoint (deleted lines and moved paragraph sources, since they have no current place in the document). Fuzzying the logic here - propogating previous section infos forward.
        
        var lastContextSectionInfo: Int?
        
        var newItems: [DiffItem] = []
        for var item in response.diff {
            
            if let sectionInfoIndex = item.sectionInfoIndex {
                lastContextSectionInfo = sectionInfoIndex
            } else {
                item.sectionInfoIndex = lastContextSectionInfo
                
            }
            
            newItems.append(item)
        }
        
        response.diff = newItems
        
        //tonitodo: finish better logic, popualte section infos only if surrounded by items with the same section infos
        /*
         
         var lastSectionInfo: Int?
         var missingSectionTitleItems: [DiffItem] = []
         
         var newItems: [DiffItem] = []
         for var item in response.diff {
             
             if let sectionInfoIndex = item.sectionInfoIndex {
                 
                 if let lastSectionInfo = lastSectionInfo,
                     !missingSectionTitleItems.isEmpty,
                     sectionInfoIndex == lastSectionInfo {
                     //populate missing section title items & clean out
                     
                     for var item in missingSectionTitleItems {
                         item.sectionInfoIndex = lastSectionInfo
                     }
                     
                     missingSectionTitleItems.removeAll()
                 }
                    
                 
                 lastSectionInfo = sectionInfoIndex
             } else {
                 if lastSectionInfo != nil {
                     //start gathering items with missing section titles
                     missingSectionTitleItems.append(item)
                 }
             }
             
             newItems.append(item)
         }
         
         response.diff = newItems
         */
    }
    
    private func viewModelsForSingle(from response: DiffResponse, theme: Theme, traitCollection: UITraitCollection, type: DiffContainerViewModel.DiffType, groupedMoveIndexes: [String: Int]) -> [DiffListGroupViewModel] {
        
        var result: [DiffListGroupViewModel] = []
        
        var sectionItems: [DiffItem] = []
        var lastItem: DiffItem?

        let packageUpSectionItemsIfNeeded = {
            
            if sectionItems.count > 0 {
                //package contexts up into change view model, append to result
                
                let changeType: DiffListChangeType = .singleRevison
                
                let changeViewModel = DiffListChangeViewModel(type: changeType, diffItems: sectionItems, theme: theme, width: 0, traitCollection: traitCollection, groupedMoveIndexes: groupedMoveIndexes, sectionInfo: response.sectionInfo)
                result.append(changeViewModel)
                sectionItems.removeAll()
            }
            
        }
        
        for item in response.diff {

            
            if item.type == .context {
                
                continue
                
            } else {
                
                if item.sectionInfoIndex != lastItem?.sectionInfoIndex {
                    packageUpSectionItemsIfNeeded()
                }
                
                sectionItems.append(item)
            }
            
            lastItem = item
            
            continue
        }
        
        packageUpSectionItemsIfNeeded()
        
        return result
    }
        
    private func viewModelsForCompare(from response: DiffResponse, theme: Theme, traitCollection: UITraitCollection, type: DiffContainerViewModel.DiffType, groupedMoveIndexes: [String: Int]) -> [DiffListGroupViewModel] {
        
        var result: [DiffListGroupViewModel] = []
        
        var contextItems: [DiffItem] = []
        var changeItems: [DiffItem] = []
        var lastItem: DiffItem?
        
        let packageUpContextItemsIfNeeded = {
            
            if contextItems.count > 0 {
                //package contexts up into context view model, append to result
                let contextViewModel = DiffListContextViewModel(diffItems: contextItems, isExpanded: false, theme: theme, width: 0, traitCollection: traitCollection)
                result.append(contextViewModel)
                contextItems.removeAll()
            }
        }
        
        let packageUpChangeItemsIfNeeded = {
            
            if changeItems.count > 0 {
                //package contexts up into change view model, append to result
                
                let changeType: DiffListChangeType
                switch type {
                case .compare:
                    changeType = .compareRevision
                default:
                    changeType = .singleRevison
                }
                
                let changeViewModel = DiffListChangeViewModel(type: changeType, diffItems: changeItems, theme: theme, width: 0, traitCollection: traitCollection, groupedMoveIndexes: groupedMoveIndexes, sectionInfo: response.sectionInfo)
                result.append(changeViewModel)
                changeItems.removeAll()
            }
            
        }
        
        for item in response.diff {
            
            if let lastItemLineNumber = lastItem?.lineNumber,
                let currentItemLineNumber = item.lineNumber {
                let delta = currentItemLineNumber - lastItemLineNumber
                if delta > 1 {
                    
                    packageUpContextItemsIfNeeded()
                    packageUpChangeItemsIfNeeded()
                    
                    //insert unedited lines view model
                    let uneditedViewModel = DiffListUneditedViewModel(numberOfUneditedLines: delta, theme: theme, width: 0, traitCollection: traitCollection)
                    result.append(uneditedViewModel)
                }
            }
            
            if item.type == .context {
                
                packageUpChangeItemsIfNeeded()
                
                contextItems.append(item)
                
            } else {
                
                packageUpContextItemsIfNeeded()
                
                changeItems.append(item)
            }
            
            lastItem = item
            
            continue
        }
        
        packageUpContextItemsIfNeeded()
        packageUpChangeItemsIfNeeded()
        
        return result
    }
}
