import Foundation

struct TransformDiffItem {
    let type: DiffItemType
    let text: String
    let highlightRanges: [DiffHighlightRange]?
    let offset: DiffItemOffset
    var sectionTitle: String?
    let lineNumber: Int?
    var moveInfo: TransformMoveInfo?
}

struct TransformMoveInfo {
    let id: String
    let linkId: String
    let linkDirection: DiffLinkDirection
    var groupedIndex: Int?
    var moveDistance: TransformMoveDistance?
}

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
    let fromIsIntro: Bool
    let toIsIntro: Bool
}

enum DiffTransformerError: Error {
    case failureTransformingNetworkModels
    case failureParsingFirstRevisionWikitext
}

// takes a DiffResponse and turns it into  [DiffListGroupViewModel]
class DiffTransformer {
    
    let type: DiffContainerViewModel.DiffType
    let siteURL: URL
    lazy var semanticContentAttribute: UISemanticContentAttribute = {
        let contentLanguageCode = siteURL.wmf_contentLanguageCode
        return MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: contentLanguageCode)
    }()
    
    init(type: DiffContainerViewModel.DiffType, siteURL: URL) {
        self.type = type
        self.siteURL = siteURL
    }
    
    func firstRevisionViewModels(from wikitext: String, theme: Theme, traitCollection: UITraitCollection) throws -> [DiffListGroupViewModel] {
        
        let lines = wikitext.split { $0.isNewline }
        
        var items: [DiffListChangeItemViewModel] = []
        for text in lines {
            let item = DiffListChangeItemViewModel(firstRevisionText: String(text), traitCollection: traitCollection, theme: theme, semanticContentAttribute: semanticContentAttribute)
            items.append(item)
        }
        
        if !wikitext.isEmpty && items.isEmpty {
            throw DiffTransformerError.failureParsingFirstRevisionWikitext
        }
        
        return [DiffListChangeViewModel(type: .singleRevison, items: items, theme: theme, width: 0, traitCollection: traitCollection, semanticContentAttribute: semanticContentAttribute)]
    }
    
    func viewModels(from response: DiffResponse, theme: Theme, traitCollection: UITraitCollection) throws -> [DiffListGroupViewModel] {
        
        let groupedMoveIndexes = self.groupedIndexesOfMoveItems(from: response)
        let transformSectionInfo = self.transformSectionInfosOfItems(from: response)
        let transformDiffItems = self.transformDiffItemsWithPopulatedLineNumbers(from: response)
        
        guard let populatedTransformDiffItems = self.populateAdditionalSectionAndMoveInfo(transformSectionInfo: transformSectionInfo, transformDiffItems: transformDiffItems, groupedMoveIndexes: groupedMoveIndexes) else {
            
            throw DiffTransformerError.failureTransformingNetworkModels
        }
        
        switch self.type {
        case .single:
            let viewModels: [DiffListGroupViewModel] = self.viewModelsForSingle(from: populatedTransformDiffItems, theme: theme, traitCollection: traitCollection)

            return viewModels
        case .compare:
            let viewModels: [DiffListGroupViewModel] = self.viewModelsForCompare(from: populatedTransformDiffItems, theme: theme, traitCollection: traitCollection)
            return viewModels
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
            guard zippedItem.0.type == .moveDestination ||
                zippedItem.0.type == .moveSource else {
                continue
            }
            
            if let linkId = zippedItem.0.moveInfo?.linkId {
                correspondingMoveItems[linkId] = (zippedItem.0, zippedItem.1)
            }
        }
        
        for var zippedItem in zipped {
            
            var isToIntro = zippedItem.1.toIsIntro
            var isFromIntro = zippedItem.1.fromIsIntro
            
            zippedItem.0.sectionTitle = zippedItem.1.to?.title ?? zippedItem.1.from?.title
            
            if let moveInfo = zippedItem.0.moveInfo {
                
                let groupedIndex = groupedMoveIndexes[moveInfo.id]
                
                var moveDistance: TransformMoveDistance? = nil
                
                if let correspondingMoveItem = correspondingMoveItems[moveInfo.id] {
                    
                    let fromSectionTitle = zippedItem.0.type == .moveSource ? zippedItem.1.from?.title : correspondingMoveItem.linkSectionInfo.from?.title
                    let toSectionTitle = zippedItem.0.type == .moveSource ? correspondingMoveItem.linkSectionInfo.to?.title : zippedItem.1.to?.title
                    let fromSectionOrder = zippedItem.0.type == .moveSource ? zippedItem.1.from?.order : correspondingMoveItem.linkSectionInfo.from?.order
                    let toSectionOrder = zippedItem.0.type == .moveSource ? correspondingMoveItem.linkSectionInfo.to?.order : zippedItem.1.to?.order
                    isToIntro = zippedItem.0.type == .moveSource ? correspondingMoveItem.linkSectionInfo.toIsIntro : zippedItem.1.toIsIntro
                    isFromIntro = zippedItem.0.type == .moveSource ? zippedItem.1.fromIsIntro : correspondingMoveItem.linkSectionInfo.fromIsIntro
                    
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
                        // fallback to line numbers
                        if let firstLineNumber = zippedItem.0.lineNumber,
                            let nextLineNumber = correspondingMoveItem.linkItem.lineNumber {
                            moveDistance = .line(amount: abs(firstLineNumber - nextLineNumber))
                        }
                    }
                }
                
                let transformMoveInfo = TransformMoveInfo(id: moveInfo.id, linkId: moveInfo.linkId, linkDirection: moveInfo.linkDirection, groupedIndex: groupedIndex, moveDistance: moveDistance)
                zippedItem.0.moveInfo = transformMoveInfo
            }
            
            if zippedItem.0.sectionTitle == nil {
                if isToIntro && isFromIntro {
                    zippedItem.0.sectionTitle = WMFLocalizedString("diff-single-intro-title", value:"Intro", comment:"Section heading on revision changes diff screen that indicates the following highlighted changes occurred in the intro section.")
                }
            }
            
            newItems.append(zippedItem.0)
        }
        
        return newItems
    }
    
    private func transformSectionInfosOfItems(from response: DiffResponse) -> [TransformSectionInfo] {
        
        var result: [TransformSectionInfo] = []
        
        var fromSections = response.from.sections
        var toSections = response.to.sections
        
        let firstFrom = fromSections.first
        let firstTo = toSections.first
        
        var lastFrom: DiffSection? = nil
        var lastTo: DiffSection? = nil
        
        var lastFromIndex = -1
        var lastToIndex = -1
        
        var currentFrom = fromSections.first
        var currentTo = toSections.first
        
        var fromIsIntro = false
        var toIsIntro = false
        for item in response.diff {
            
            // from side
            var fromSide: TransformSectionInfo.Side?
            
            if let itemFromOffset = item.offset.from {
                while currentFrom != nil &&
                currentFrom!.offset <= itemFromOffset {
                    
                        lastFrom = fromSections.removeFirst()
                        lastFromIndex = lastFromIndex + 1
                        currentFrom = fromSections.first
                }
                
                if let lastFrom = lastFrom {
                    fromSide = TransformSectionInfo.Side(title: lastFrom.heading, order: lastFromIndex)
                }
                
                if let firstFromOffset = firstFrom?.offset,
                    fromSide == nil {
                    fromIsIntro = itemFromOffset < firstFromOffset
                }
            }
            
            
            // to side
            var toSide: TransformSectionInfo.Side?
            
            if let itemToOffset = item.offset.to {
                while currentTo != nil &&
                currentTo!.offset <= itemToOffset {
                    
                        lastTo = toSections.removeFirst()
                        lastToIndex = lastToIndex + 1
                        currentTo = toSections.first
                }
                
                if let lastTo = lastTo {
                    toSide = TransformSectionInfo.Side(title: lastTo.heading, order: lastToIndex)
                }
                
                if let firstToOffset = firstTo?.offset,
                    toSide == nil {
                    toIsIntro = itemToOffset < firstToOffset
                }
            }
            
            result.append(TransformSectionInfo(from: fromSide, to: toSide, fromIsIntro: fromIsIntro, toIsIntro: toIsIntro))
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
            
            var transformMoveInfo: TransformMoveInfo?
            if let moveInfo = item.moveInfo {
                transformMoveInfo = TransformMoveInfo(id: moveInfo.id, linkId: moveInfo.linkId, linkDirection: moveInfo.linkDirection, groupedIndex: nil, moveDistance: nil)
            }
            
            let transformDiffItem: TransformDiffItem
            
            if let lineNumber = item.lineNumber {
                lastLineNumber = lineNumber
                transformDiffItem = TransformDiffItem(type: item.type, text: item.text, highlightRanges: item.highlightRanges, offset: item.offset, sectionTitle: nil, lineNumber: lineNumber, moveInfo: transformMoveInfo)
            } else {
                transformDiffItem = TransformDiffItem(type: item.type, text: item.text, highlightRanges: item.highlightRanges, offset: item.offset, sectionTitle: nil, lineNumber: lastLineNumber, moveInfo: transformMoveInfo)
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
                // package contexts up into change view model, append to result

                let changeViewModel = DiffListChangeViewModel(type: .singleRevison, diffItems: sectionItems, theme: theme, width: 0, traitCollection: traitCollection, semanticContentAttribute: self.semanticContentAttribute)

                result.append(changeViewModel)
                sectionItems.removeAll()
            }
            
        }
        
        for item in transformDiffItems {

            
            if item.type == .context {
                
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
                // package contexts up into context view model, append to result
                let contextViewModel = DiffListContextViewModel(diffItems: contextItems, isExpanded: UIAccessibility.isVoiceOverRunning, theme: theme, width: 0, traitCollection: traitCollection, semanticContentAttribute: self.semanticContentAttribute)
                result.append(contextViewModel)
                contextItems.removeAll()
            }
        }
        
        let packageUpChangeItemsIfNeeded = {
            
            if changeItems.count > 0 {
                // package contexts up into change view model, append to result

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
                    
                    // insert unedited lines view model
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
