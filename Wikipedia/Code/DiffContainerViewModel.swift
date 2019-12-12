
import Foundation

final class DiffContainerViewModel {
    
    enum DiffType {
        case single
        case compare
    }
    
    enum State {
        case loading
        case empty
        case data
        case error(error: Error)
    }
    
    var headerViewModel: DiffHeaderViewModel?
    let type: DiffType
    var listViewModel: [DiffListGroupViewModel]?
    
    var state: State = .loading {
        didSet {
            stateHandler?(oldValue)
        }
    }
    var stateHandler: ((_ oldState: DiffContainerViewModel.State) -> Void)?
    
    init(type: DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision?, listViewModel: [DiffListGroupViewModel]?, articleTitle: String?, byteDifference: Int?, theme: Theme) {
        self.type = type
        
        if let toModel = toModel,
            let articleTitle = articleTitle {
            self.headerViewModel = DiffHeaderViewModel(diffType: type, fromModel: fromModel, toModel: toModel, articleTitle: articleTitle, byteDifference: byteDifference, theme: theme)
        } else {
            self.headerViewModel = nil
        }
        
        self.listViewModel = listViewModel
    }
}
