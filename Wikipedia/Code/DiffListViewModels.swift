
import Foundation

protocol DiffListGroupViewModel {
    
}

struct DiffListItemHighlightRange {
    
    enum HighlightType {
        case added
        case deleted
    }
    
    let start: Int
    let length: Int
    let type: HighlightType
}

struct DiffListItemViewModel {
    let text: String
    let highlightedRanges: [DiffListItemHighlightRange]
}

typealias DiffListChangeTypeSectionTitle = String
typealias DiffListChangeTypeLines = String

enum DiffListChangeType {
    case singleRevison(DiffListChangeTypeSectionTitle)
    case compareRevision(DiffListChangeTypeLines)
}

struct DiffListChangeViewModel: DiffListGroupViewModel {
    
    let type: DiffListChangeType
    let items: [DiffListItemViewModel]
}

struct DiffListContextViewModel: DiffListGroupViewModel {
    let lines: String
    let isExpanded: Bool
    let items: [String]
}

struct DiffListCompareUneditedViewModel: DiffListGroupViewModel {
    let numberOfUneditedLines: Int
}
