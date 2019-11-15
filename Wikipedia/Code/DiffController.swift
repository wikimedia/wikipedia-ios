
import Foundation

struct TransformDiffItem {
    let diffItem: DiffItem
    var sectionTitle: String?
    let lineNumber: Int?
    var transformMoveInfo: TransformMoveInfo?
}

struct TransformMoveInfo {
    let moveInfo: DiffMoveInfo
    var groupedIndex: Int?
    var moveDistance: TransformMoveDistance?
}

//eventually used to power "Moved [down/up] n lines / Moved [down/up] n sections" text in diff
enum TransformMoveDistance {
    case line(amount: Int)
    case section(amount: Int)
}

struct TransformSectionInfo {
    
    struct Side {
        let title: String
        let order: Int
    }
    
    let from: Side?
    let to: Side?
}

enum DiffError: Error {
    case generateUrlFailure
    case missingDiffResponseFailure
    case missingUrlResponseFailure
    case fetchRevisionIDFailure
    case noPreviousRevisionID
    case unrecognizedHardcodedIdsForIntermediateCounts
    case failureTransformingNetworkModels
    
    var localizedDescription: String {
        return CommonStrings.genericErrorDescription
    }
}

class DiffController {
    
    let diffFetcher: DiffFetcher
    let revisionFetcher: WMFArticleRevisionFetcher
    let globalUserInfoFetcher: GlobalUserInfoFetcher
    let diffThanker: DiffThanker
    let articleTitle: String
    let siteURL: URL
    lazy var semanticContentAttribute: UISemanticContentAttribute = {
        let language = siteURL.wmf_language
        return MWLanguageInfo.semanticContentAttribute(forWMFLanguage: language)
    }()
    let type: DiffContainerViewModel.DiffType
    
    init(siteURL: URL, articleTitle: String, diffFetcher: DiffFetcher = DiffFetcher(), revisionFetcher: WMFArticleRevisionFetcher = WMFArticleRevisionFetcher(), globalUserInfoFetcher: GlobalUserInfoFetcher = GlobalUserInfoFetcher(), diffThanker: DiffThanker = DiffThanker(), type: DiffContainerViewModel.DiffType) {
        self.diffFetcher = diffFetcher
        self.revisionFetcher = revisionFetcher
        self.globalUserInfoFetcher = globalUserInfoFetcher
        self.diffThanker = diffThanker
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
    
    func thankRevisionAuthor(toRevisionId: Int, completion: @escaping ((Result<DiffThankerResult, Error>) -> Void)) {
        diffThanker.thank(siteURL: siteURL, rev: toRevisionId, completion: completion)
    }
    
    private func fetchSingleNextRevision(toRevisionId: Int, completion: @escaping ((Result<Int, Error>) -> Void)) {
        
        guard let articleTitle = (articleTitle as NSString).wmf_normalizedPageTitle(),
            let articleURL = siteURL.wmf_URL(withPath: "/wiki/\(articleTitle)", isMobile: true) else {
            return
        }
        
        revisionFetcher.fetchLatestRevisions(forArticleURL: articleURL, resultLimit: 2, startingWithRevision: NSNumber(value: toRevisionId), endingWithRevision: nil, failure: { (error) in
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
//
//        let queue = DispatchQueue.global(qos: .userInitiated)
//
//        queue.async { [weak self] in
//
//        //diffFetcher.fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, siteURL: siteURL) { [weak self] (result) in
//
//            guard let self = self else { return }
//
//            do {
//
//            let url = Bundle.main.url(forResource: "test", withExtension: "json")!
//            let data = try Data(contentsOf: url)
//            let diffResponse = try JSONDecoder().decode(DiffResponse.self, from: data)
//
//                let groupedMoveIndexes = self.groupedIndexesOfMoveItems(from: diffResponse)
//                let transformSectionInfo = self.transformSectionInfosOfItems(from: diffResponse)
//                let transformDiffItems = self.transformDiffItemsWithPopulatedLineNumbers(from: diffResponse)
//
//                guard let populatedTransformDiffItems = self.populateAdditionalSectionAndMoveInfo(transformSectionInfo: transformSectionInfo, transformDiffItems: transformDiffItems, groupedMoveIndexes: groupedMoveIndexes) else {
//                    completion(.failure(DiffError.failureTransformingNetworkModels))
//                    return
//                }
//
//                switch self.type {
//                case .single:
//                    let response: [DiffListGroupViewModel] = self.viewModelsForSingle(from: populatedTransformDiffItems, theme: theme, traitCollection: traitCollection)
//
//                    completion(.success(response))
//                case .compare:
//                    let response: [DiffListGroupViewModel] = self.viewModelsForCompare(from: populatedTransformDiffItems, theme: theme, traitCollection: traitCollection)
//                    completion(.success(response))
//                }
//
//            } catch (let error) {
//                completion(.failure(error))
//            }
//        }
        
        diffFetcher.fetchDiff(fromRevisionId: fromRevisionId, toRevisionId: toRevisionId, siteURL: siteURL) { [weak self] (result) in

            guard let self = self else { return }

            switch result {
            case .success(let diffResponse):

                let groupedMoveIndexes = self.groupedIndexesOfMoveItems(from: diffResponse)
                let transformSectionInfo = self.transformSectionInfosOfItems(from: diffResponse)
                let transformDiffItems = self.transformDiffItemsWithPopulatedLineNumbers(from: diffResponse)
                
                guard let populatedTransformDiffItems = self.populateAdditionalSectionAndMoveInfo(transformSectionInfo: transformSectionInfo, transformDiffItems: transformDiffItems, groupedMoveIndexes: groupedMoveIndexes) else {
                    completion(.failure(DiffError.failureTransformingNetworkModels))
                    return
                }
                
                switch self.type {
                case .single:
                    let response: [DiffListGroupViewModel] = self.viewModelsForSingle(from: populatedTransformDiffItems, theme: theme, traitCollection: traitCollection)

                    completion(.success(response))
                case .compare:
                    let response: [DiffListGroupViewModel] = self.viewModelsForCompare(from: populatedTransformDiffItems, theme: theme, traitCollection: traitCollection)
                    completion(.success(response))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func populateAdditionalSectionAndMoveInfo(transformSectionInfo: [TransformSectionInfo], transformDiffItems: [TransformDiffItem], groupedMoveIndexes: [String: Int]) -> [TransformDiffItem]? {
        
        guard transformDiffItems.count == transformSectionInfo.count,
            transformDiffItems.count == transformDiffItems.count else {
            assertionFailure("Expecting section info count to equal number of diff items")
            return nil
        }
        
        var newItems: [TransformDiffItem] = []
        let zipped = zip(transformDiffItems, transformSectionInfo)
        
        var correspondingMoveItems: [String: (linkItem: TransformDiffItem, linkSectionInfo: TransformSectionInfo)] = [:]
        for zippedItem in zipped {
            guard zippedItem.0.diffItem.type == .moveDestination ||
                zippedItem.0.diffItem.type == .moveSource else {
                continue
            }
            
            if let linkId = zippedItem.0.diffItem.moveInfo?.linkId {
                correspondingMoveItems[linkId] = (zippedItem.0, zippedItem.1)
            }
        }
        
        for var zippedItem in zipped {
            
            zippedItem.0.sectionTitle = zippedItem.1.to?.title ?? zippedItem.1.from?.title
            
            if let moveInfo = zippedItem.0.diffItem.moveInfo {
                
                let groupedIndex = groupedMoveIndexes[moveInfo.id]
                
                var moveDistance: TransformMoveDistance? = nil
                
                if let correspondingMoveItem = correspondingMoveItems[moveInfo.id] {
                    
                    let fromSectionTitle = zippedItem.0.diffItem.type == .moveSource ? zippedItem.1.from?.title : correspondingMoveItem.linkSectionInfo.from?.title
                    let toSectionTitle = zippedItem.0.diffItem.type == .moveSource ? correspondingMoveItem.linkSectionInfo.to?.title : zippedItem.1.to?.title
                    let fromSectionOrder = zippedItem.0.diffItem.type == .moveSource ? zippedItem.1.from?.order : correspondingMoveItem.linkSectionInfo.from?.order
                    let toSectionOrder = zippedItem.0.diffItem.type == .moveSource ? correspondingMoveItem.linkSectionInfo.to?.order : zippedItem.1.to?.order
                    
                    if let fromSectionTitle = fromSectionTitle,
                        let toSectionTitle = toSectionTitle,
                        let fromSectionOrder = fromSectionOrder,
                        let toSectionOrder = toSectionOrder {
                            
                        switch (fromSectionTitle == toSectionTitle, fromSectionOrder == toSectionOrder) {
                            
                            case (false, false):
                                moveDistance = .section(amount: abs(fromSectionOrder - toSectionOrder))
                            default:
                                break
                        }
                    }
                    
                    if moveDistance == nil {
                        //fallback to line numbers
                        if let firstLineNumber = zippedItem.0.lineNumber,
                            let nextLineNumber = correspondingMoveItem.linkItem.lineNumber {
                            moveDistance = .line(amount: abs(firstLineNumber - nextLineNumber))
                        }
                    }
                }
                
                let transformMoveInfo = TransformMoveInfo(moveInfo: moveInfo, groupedIndex: groupedIndex, moveDistance: moveDistance)
                zippedItem.0.transformMoveInfo = transformMoveInfo
            }
            
            newItems.append(zippedItem.0)
        }
        
        return newItems
    }
    
    private func transformSectionInfosOfItems(from response: DiffResponse) -> [TransformSectionInfo] {
        
        var result: [TransformSectionInfo] = []
        
        var fromSections = response.from.sections
        var toSections = response.to.sections
        
        var lastFrom: DiffSection? = nil
        var lastTo: DiffSection? = nil
        
        var lastFromIndex = -1
        var lastToIndex = -1
        
        var currentFrom = fromSections.first
        var currentTo = toSections.first
        
        for item in response.diff {
            
            //from side
            var fromSide: TransformSectionInfo.Side?
            
            if let itemFromOffset = item.offset?.from {
                while currentFrom != nil &&
                currentFrom!.offset <= itemFromOffset {
                    
                        lastFrom = fromSections.removeFirst()
                        lastFromIndex = lastFromIndex + 1
                        currentFrom = fromSections.first
                }
                
                if let lastFrom = lastFrom {
                    fromSide = TransformSectionInfo.Side(title: lastFrom.heading, order: lastFromIndex)
                }
            }
            
            
            //to side
            var toSide: TransformSectionInfo.Side?
            
            if let itemToOffset = item.offset?.to {
                while currentTo != nil &&
                currentTo!.offset <= itemToOffset {
                    
                        lastTo = toSections.removeFirst()
                        lastToIndex = lastToIndex + 1
                        currentTo = toSections.first
                }
                
                if let lastTo = lastTo {
                    toSide = TransformSectionInfo.Side(title: lastTo.heading, order: lastToIndex)
                }
            }
            
            
            result.append(TransformSectionInfo(from: fromSide, to: toSide))
        }
        
        return result
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
    
    private func transformDiffItemsWithPopulatedLineNumbers(from response: DiffResponse) -> [TransformDiffItem] {
        
        var items: [TransformDiffItem] = []
        
        var lastLineNumber: Int?
        for item in response.diff {
            
            let transformDiffItem: TransformDiffItem
            if let lineNumber = item.lineNumber {
                lastLineNumber = lineNumber
                transformDiffItem = TransformDiffItem(diffItem: item, sectionTitle: nil, lineNumber: lineNumber, transformMoveInfo: nil)
            } else {
                transformDiffItem = TransformDiffItem(diffItem: item, sectionTitle: nil, lineNumber: lastLineNumber, transformMoveInfo: nil)
            }
            
            items.append(transformDiffItem)
        }
        
        return items
    }
    
    private func viewModelsForSingle(from transformDiffItems: [TransformDiffItem], theme: Theme, traitCollection: UITraitCollection) -> [DiffListGroupViewModel] {
        
        var result: [DiffListGroupViewModel] = []
        
        var sectionItems: [TransformDiffItem] = []
        var lastItem: TransformDiffItem?

        let packageUpSectionItemsIfNeeded = {
            
            if sectionItems.count > 0 {
                //package contexts up into change view model, append to result

                let changeViewModel = DiffListChangeViewModel(type: .singleRevison, diffItems: sectionItems, theme: theme, width: 0, traitCollection: traitCollection, semanticContentAttribute: self.semanticContentAttribute)

                result.append(changeViewModel)
                sectionItems.removeAll()
            }
            
        }
        
        for item in transformDiffItems {

            
            if item.diffItem.type == .context {
                
                continue
                
            } else {
                
                if item.sectionTitle != lastItem?.sectionTitle {
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
        
    private func viewModelsForCompare(from transformDiffItems: [TransformDiffItem], theme: Theme, traitCollection: UITraitCollection) -> [DiffListGroupViewModel] {
        
        var result: [DiffListGroupViewModel] = []
        
        var contextItems: [TransformDiffItem] = []
        var changeItems: [TransformDiffItem] = []
        var lastItem: TransformDiffItem?
        
        let packageUpContextItemsIfNeeded = {
            
            if contextItems.count > 0 {
                //package contexts up into context view model, append to result
                let contextViewModel = DiffListContextViewModel(diffItems: contextItems, isExpanded: false, theme: theme, width: 0, traitCollection: traitCollection, semanticContentAttribute: self.semanticContentAttribute)
                result.append(contextViewModel)
                contextItems.removeAll()
            }
        }
        
        let packageUpChangeItemsIfNeeded = {
            
            if changeItems.count > 0 {
                //package contexts up into change view model, append to result

                let changeViewModel = DiffListChangeViewModel(type: .compareRevision, diffItems: changeItems, theme: theme, width: 0, traitCollection: traitCollection, semanticContentAttribute: self.semanticContentAttribute)

                result.append(changeViewModel)
                changeItems.removeAll()
            }
            
        }
        
        for item in transformDiffItems {
            
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
            
            if item.diffItem.type == .context {
                
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
