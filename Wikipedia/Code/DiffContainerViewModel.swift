
import Foundation

final class DiffContainerViewModel {
    
    enum DiffType {
        case single(byteDifference: Int)
        case compare(articleTitle: String)
    }
    
    enum State {
        case loading
        case empty
        case data
        case error(error: Error)
    }
    
    let headerViewModel: DiffHeaderViewModel?
    let type: DiffType
    var listViewModel: [DiffListGroupViewModel]?
    
    var state: State = .loading {
        didSet {
            stateHandler?()
        }
    }
    var stateHandler: (() -> Void)?
    
    init(type: DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision?, listViewModel: [DiffListGroupViewModel]?, theme: Theme) {
        self.type = type
        
        if let toModel = toModel {
            self.headerViewModel = DiffHeaderViewModel(diffType: type, fromModel: fromModel, toModel: toModel, theme: theme)
        } else {
            self.headerViewModel = nil
        }
        
        self.listViewModel = listViewModel
    }
}
