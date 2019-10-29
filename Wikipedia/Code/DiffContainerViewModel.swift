
import Foundation

final class DiffContainerViewModel {
    
    enum DiffType {
        case single(byteDifference: Int)
        case compare(articleTitle: String)
    }
    
    let headerViewModel: DiffHeaderViewModel
    let type: DiffType
    var listViewModel: [DiffListGroupViewModel]?
    
    init(type: DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision, listViewModel: [DiffListGroupViewModel]?, theme: Theme) {
        self.type = type
        self.headerViewModel = DiffHeaderViewModel(diffType: type, fromModel: fromModel, toModel: toModel, theme: theme)
        self.listViewModel = listViewModel
    }
}
