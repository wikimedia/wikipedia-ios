import Foundation

struct DiffSection: Codable {
    let level: Int
    let heading: String
    let offset: Int
}

struct DiffItemOffset: Codable {
    let from: Int?
    let to: Int?
}

struct DiffSideMetaData: Codable {
    let sections: [DiffSection]
}

struct DiffResponse: Codable {
    let diff: [DiffItem]
    let from: DiffSideMetaData
    let to: DiffSideMetaData
}

enum DiffItemType: Int, Codable {
    case context
    case addLine
    case deleteLine
    case change
    case moveSource
    case moveDestination

    var isMoveBased: Bool {
        return self == .moveSource || self == .moveDestination
    }
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
    let type: DiffItemType
    let text: String
    let highlightRanges: [DiffHighlightRange]?
    let moveInfo: DiffMoveInfo?
    let offset: DiffItemOffset
    let lineNumber: Int?
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
            lhs.offset == rhs.offset
    }
}

extension DiffMoveInfo: Equatable {
    
}

extension DiffItemOffset: Equatable {
    
}

extension DiffHighlightRange: Equatable {
    
}
