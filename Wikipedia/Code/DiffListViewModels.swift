
import Foundation

protocol DiffListGroupViewModel {
    var theme: Theme { get set }
}

final class DiffListItemHighlightRange {
    
    enum HighlightType {
        case added
        case deleted
    }
    
    let start: Int
    let length: Int
    let type: HighlightType
    
    init(start: Int, length: Int, type: HighlightType) {
        self.start = start
        self.length = length
        self.type = type
    }
}

final class DiffListItemViewModel {
    let text: String
    let highlightedRanges: [DiffListItemHighlightRange]
    
    init(text: String, highlightedRanges: [DiffListItemHighlightRange]) {
        self.text = text
        self.highlightedRanges = highlightedRanges
    }
}

typealias DiffListChangeTypeSectionTitle = String
typealias DiffListChangeTypeLines = String

enum DiffListChangeType {
    case singleRevison(DiffListChangeTypeSectionTitle)
    case compareRevision(DiffListChangeTypeLines)
}

final class DiffListChangeViewModel: DiffListGroupViewModel {
    
    let type: DiffListChangeType
    let items: [DiffListItemViewModel]
    var theme: Theme
    
    init(type: DiffListChangeType, items: [DiffListItemViewModel], theme: Theme) {
        self.type = type
        self.items = items
        self.theme = theme
    }
}

final class DiffListContextViewModel: DiffListGroupViewModel {
    let lines: String
    var isExpanded: Bool
    let items: [String]
    var theme: Theme
    
    init(lines: String, isExpanded: Bool, items: [String], theme: Theme) {
        self.lines = lines
        self.isExpanded = isExpanded
        self.items = items
        self.theme = theme
    }
}

final class DiffListCompareUneditedViewModel: DiffListGroupViewModel {
    let numberOfUneditedLines: Int
    var theme: Theme
    
    init(numberOfUneditedLines: Int, theme: Theme) {
        self.numberOfUneditedLines = numberOfUneditedLines
        self.theme = theme
    }
}
