
import Foundation

class DiffController {
    
    func fetchDiff(theme: Theme, traitCollection: UITraitCollection, type: DiffContainerViewModel.DiffType, completion: ((Result<[DiffListGroupViewModel], Error>) -> Void)? = nil) {
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        queue.async { [weak self] in
            
            guard let self = self else { return }
            
            do {

                 let url = Bundle.main.url(forResource: "ObamaTest", withExtension: "json")!
                 let data = try Data(contentsOf: url)
                 let result = try JSONDecoder().decode(DiffResponse.self, from: data)
                
                let groupedMoveIndexes = self.groupedIndexesOfMoveItems(from: result)

                switch type {
                case .single:
                    let response: [DiffListGroupViewModel] = self.viewModelsForSingle(from: result, theme: theme, traitCollection: traitCollection, type: type, groupedMoveIndexes: groupedMoveIndexes)
                    completion?(.success(response))
                case .compare:
                    let response: [DiffListGroupViewModel] = self.viewModelsForCompare(from: result, theme: theme, traitCollection: traitCollection, type: type, groupedMoveIndexes: groupedMoveIndexes)
                    completion?(.success(response))
                }
            }
            catch (let error) {
                completion?(.failure(error))
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
    
    private func viewModelsForSingle(from response: DiffResponse, theme: Theme, traitCollection: UITraitCollection, type: DiffContainerViewModel.DiffType, groupedMoveIndexes: [String: Int]) -> [DiffListGroupViewModel] {
        
        var result: [DiffListGroupViewModel] = []
        
        var sectionItems: [DiffItem] = []
        var lastItem: DiffItem?

        let packageUpSectionItemsIfNeeded = {
            
            if sectionItems.count > 0 {
                //package contexts up into change view model, append to result
                
                let changeType: DiffListChangeType = .singleRevison
                
                let changeViewModel = DiffListChangeViewModel(type: changeType, diffItems: sectionItems, theme: theme, width: 0, traitCollection: traitCollection, groupedMoveIndexes: groupedMoveIndexes, sectionTitles: response.sectionTitles)
                result.append(changeViewModel)
                sectionItems.removeAll()
            }
            
        }
        
        for item in response.diff {

            
            if item.type == .context {
                
                continue
                
            } else {
                
                if item.sectionTitleIndex != lastItem?.sectionTitleIndex {
                    packageUpSectionItemsIfNeeded()
                }
                
                sectionItems.append(item)
            }
            
            lastItem = item
            
            continue
        }
        
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
                
                let changeViewModel = DiffListChangeViewModel(type: changeType, diffItems: changeItems, theme: theme, width: 0, traitCollection: traitCollection, groupedMoveIndexes: groupedMoveIndexes, sectionTitles: response.sectionTitles)
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
        
        return result
    }
}
