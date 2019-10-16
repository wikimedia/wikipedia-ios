
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
                
                let response: [DiffListGroupViewModel] = self.viewModels(from: result, theme: theme, traitCollection: traitCollection, type: type)
                    completion?(.success(response))
            }
            catch (let error) {
                completion?(.failure(error))
            }
        }
    }
    
    private func viewModels(from response: DiffResponse, theme: Theme, traitCollection: UITraitCollection, type: DiffContainerViewModel.DiffType) -> [DiffListGroupViewModel] {
        
        var result: [DiffListGroupViewModel] = []
        
        var contextItems: [DiffItem] = []
        var changeItems: [DiffItem] = []
        var lastItem: DiffItem?
        for item in response.diff {
            
            if let lastItemLineNumber = lastItem?.lineNumber,
                let currentItemLineNumber = item.lineNumber {
                let delta = currentItemLineNumber - lastItemLineNumber
                if delta > 1 {
                    //insert unedited lines view model
                    let uneditedViewModel = DiffListUneditedViewModel(numberOfUneditedLines: delta, theme: theme, width: 0, traitCollection: traitCollection)
                    result.append(uneditedViewModel)
                }
            }
            
            if item.type == .context {
                contextItems.append(item)
                
                if changeItems.count > 0 {
                    //package contexts up into context view model, append to result
                    
                    let changeType: DiffListChangeType
                    switch type {
                    case .compare:
                        changeType = .compareRevision
                    default:
                        changeType = .singleRevison
                    }
                    
                    let changeViewModel = DiffListChangeViewModel(type: changeType, diffItems: changeItems, theme: theme, width: 0, traitCollection: traitCollection)
                    result.append(changeViewModel)
                    changeItems.removeAll()
                }
            } else {
                
                if contextItems.count > 0 {
                    //package contexts up into context view model, append to result
                    let contextViewModel = DiffListContextViewModel(diffItems: contextItems, isExpanded: false, theme: theme, width: 0, traitCollection: traitCollection)
                    result.append(contextViewModel)
                    contextItems.removeAll()
                }
                
                changeItems.append(item)
            }
            
            lastItem = item
            
            continue
        }
        
        return result
    }
}
