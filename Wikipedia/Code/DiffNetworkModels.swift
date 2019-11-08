
import Foundation

struct SectionInfo: Codable {
    let title: String
    let location: Int
}

struct DiffResponse: Codable {
    var diff: [DiffItem] //tonitodo: change back to let after finished hardcoding for user testing
    var sectionInfo: [SectionInfo]? //tonitodo: change back to let after finished hardcoding for user testing
}

enum DiffItemType: Int, Codable {
    case context
    case addLine
    case deleteLine
    case change
    case moveSource
    case moveDestination
}

enum DiffHighlightRangeType: Int, Codable {
    case add
    case delete
}

enum DiffLinkDirection: Int, Codable {
    case down
    case up
}

struct DiffHighlightRange: Codable {
    let start: Int
    let length: Int
    let type: DiffHighlightRangeType
}

struct DiffItem: Codable {
    var lineNumber: Int?
    let type: DiffItemType
    let text: String
    let highlightRanges: [DiffHighlightRange]?
    let moveInfo: DiffMoveInfo?
    var sectionInfoIndex: Int?
}

struct DiffMoveInfo: Codable {
    let id: String
    let linkId: String
    let linkDirection: DiffLinkDirection
}

extension DiffItem: Equatable {
    static func == (lhs: DiffItem, rhs: DiffItem) -> Bool {
        return lhs.lineNumber == rhs.lineNumber &&
            lhs.type == rhs.type &&
            lhs.text == rhs.text &&
            lhs.highlightRanges == rhs.highlightRanges &&
            lhs.moveInfo == rhs.moveInfo &&
            lhs.sectionInfoIndex == rhs.sectionInfoIndex
    }
}

extension DiffHighlightRange: Equatable {
    
}

extension DiffMoveInfo: Equatable {
    
}
