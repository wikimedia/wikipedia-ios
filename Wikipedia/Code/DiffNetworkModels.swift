
import Foundation

struct DiffResponse: Codable {
    let diff: Diff
}

struct Diff: Codable {
    let diff: [DiffItem]
    let sectionTitles: [String]?
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
    let lineNumber: Int?
    let type: DiffItemType
    let text: String
    let highlightRanges: [DiffHighlightRange]?
    let moveInfo: DiffMoveInfo?
    let sectionTitleIndex: Int?
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
            lhs.sectionTitleIndex == rhs.sectionTitleIndex
    }
}

extension DiffHighlightRange: Equatable {
    
}

extension DiffMoveInfo: Equatable {
    
}
