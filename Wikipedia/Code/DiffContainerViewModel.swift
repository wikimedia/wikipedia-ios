
import Foundation

final class DiffContainerViewModel {
    
    enum DiffType {
        case single(byteDifference: Int)
        case compare(articleTitle: String, numberOfIntermediateRevisions: Int, numberOfIntermediateUsers: Int)
    }
    
    let headerViewModel: DiffHeaderViewModel
    let navBarTitle: String?
    let type: DiffType
    let listViewModel: [DiffListGroupViewModel]?
    var theme: Theme {
        didSet {
            if let listViewModel = listViewModel {
                for var item in listViewModel {
                    item.theme = theme
                }
            }
            
            headerViewModel.theme = theme
        }
    }
    
    init(type: DiffType, fromModel: StubRevisionModel, toModel: StubRevisionModel, theme: Theme, listViewModel: [DiffListGroupViewModel]?) {
        self.type = type
        self.headerViewModel = DiffHeaderViewModel(type: type, fromModel: fromModel, toModel: toModel, theme: theme)
        switch type {
        case .single(_):
            navBarTitle = nil
        case .compare(_):
            navBarTitle = WMFLocalizedString("diff-compare-title", value: "Compare Revisions", comment: "Title label that shows in the navigation bar when scrolling and comparing revisions.")
        }
        self.listViewModel = listViewModel
        self.theme = theme
    }
}
