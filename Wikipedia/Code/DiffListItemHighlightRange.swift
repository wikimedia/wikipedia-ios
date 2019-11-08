
import Foundation

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
