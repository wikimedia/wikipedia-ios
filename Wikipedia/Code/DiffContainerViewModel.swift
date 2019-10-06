
import Foundation

struct DiffContainerViewModel {
    
    enum DiffType {
        case single(byteDifference: Int)
        case compare(articleTitle: String, numIntermediateRevisions: Int, numIntermediateEditors: Int, scrollYOffset: CGFloat, beginSquishYOffset: CGFloat)
    }
    
    let headerViewModel: DiffHeaderViewModel
    let title: String?
    let type: DiffType
    let listViewModel: [DiffListGroupViewModel]?
    
    init(type: DiffType, fromModel: StubRevisionModel, toModel: StubRevisionModel, theme: Theme, listViewModel: [DiffListGroupViewModel]?) {
        self.type = type
        self.headerViewModel = DiffHeaderViewModel(type: type, fromModel: fromModel, toModel: toModel, theme: theme)
        switch type {
        case .single(_):
            title = nil
        case .compare(_):
            title = WMFLocalizedString("diff-compare-title", value: "Compare Revisions", comment: "Title label that shows in the navigation bar when scrolling and comparing revisions.")
        }
        self.listViewModel = listViewModel
    }
}
