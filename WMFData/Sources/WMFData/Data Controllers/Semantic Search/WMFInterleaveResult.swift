import Foundation

public enum WMFInterleaveSearchType: String, Sendable, Equatable {
    case lexical
    case semantic

    /// One character of the coin flips log: `L` if lexical picked first in that round, `S` if semantic did.
    public var logCode: Character {
        switch self {
        case .lexical: return "L"
        case .semantic: return "S"
        }
    }
}

public struct WMFInterleaveSlot<Item: Sendable>: Sendable {
    public let item: Item
    /// The retriever that placed the item.
    public let searchType: WMFInterleaveSearchType
    /// 1-based position of the item in its own retriever's input list, counting skipped duplicates.
    public let rank: Int
    /// True if the item's page ID appears anywhere in the other retriever's input list.
    public let alsoInOther: Bool
}

extension WMFInterleaveSlot: Equatable where Item: Equatable {}

public struct WMFInterleaveResult<Item: Sendable>: Sendable {
    public let slots: [WMFInterleaveSlot<Item>]
    /// One entry per coin used, in order: the retriever that picked first in that round.
    public let coinFlips: [WMFInterleaveSearchType]
    public let seed: UInt64
    public let mergeVersion: Int

    /// One character per coin used, in order. Empty if no coin was used.
    public var coinFlipsLog: String {
        return String(coinFlips.map { $0.logCode })
    }

    /// The seed as an unsigned decimal string, since JSON numbers cannot hold every 64-bit value.
    public var seedLog: String {
        return String(seed)
    }
}

extension WMFInterleaveResult: Equatable where Item: Equatable {}
