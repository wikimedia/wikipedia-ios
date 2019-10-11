
import Foundation

struct DiffResponse: Codable {
    let diff: [DiffItem]
    let sectionTitles: [String]
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
