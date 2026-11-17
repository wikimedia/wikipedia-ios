import Foundation

/// Team-Draft merge of lexical and semantic results, as defined in the Team-Draft merge spec shared with
/// Android. It is a pure function of its inputs and must not read UI state, the clock or any other source of
/// randomness. Any change to the output for the same inputs must bump `mergeVersion` and regenerate the
/// shared test vectors.
public enum WMFSearchResultsInterleaver {

    public static let mergeVersion = 1

    /// A fresh, uniformly random seed. Generate one per merged list, outside of `merge`.
    public static func newSeed() -> UInt64 {
        return UInt64.random(in: UInt64.min...UInt64.max)
    }

    public static func merge<Item: Sendable>(
        lexical: [Item],
        semantic: [Item],
        listLength: Int,
        seed: UInt64,
        pageID: (Item) -> Int
    ) -> WMFInterleaveResult<Item> {
        var random = WMFSplitMix64(seed: seed)
        var placedPageIDs = Set<Int>()
        var lexicalPicker = Picker(searchType: .lexical, items: lexical, pageIDs: Set(lexical.map(pageID)))
        var semanticPicker = Picker(searchType: .semantic, items: semantic, pageIDs: Set(semantic.map(pageID)))
        var slots: [WMFInterleaveSlot<Item>] = []
        var coinFlips: [WMFInterleaveSearchType] = []

        func pick(_ picker: inout Picker<Item>, other: Picker<Item>) {
            guard let index = picker.nextIndex(placedPageIDs: placedPageIDs, pageID: pageID) else { return }
            let item = picker.items[index]
            let id = pageID(item)
            placedPageIDs.insert(id)
            slots.append(WMFInterleaveSlot(item: item, searchType: picker.searchType, rank: index + 1, alsoInOther: other.contains(id)))
        }

        while slots.count < listLength {
            let lexicalHasNext = lexicalPicker.nextIndex(placedPageIDs: placedPageIDs, pageID: pageID) != nil
            let semanticHasNext = semanticPicker.nextIndex(placedPageIDs: placedPageIDs, pageID: pageID) != nil

            if lexicalHasNext && semanticHasNext {
                let lexicalFirst = random.nextCoin() == 0
                coinFlips.append(lexicalFirst ? .lexical : .semantic)
                if lexicalFirst {
                    pick(&lexicalPicker, other: semanticPicker)
                    if slots.count < listLength {
                        pick(&semanticPicker, other: lexicalPicker)
                    }
                } else {
                    pick(&semanticPicker, other: lexicalPicker)
                    if slots.count < listLength {
                        pick(&lexicalPicker, other: semanticPicker)
                    }
                }
            } else if lexicalHasNext {
                pick(&lexicalPicker, other: semanticPicker)
            } else if semanticHasNext {
                pick(&semanticPicker, other: lexicalPicker)
            } else {
                break
            }
        }

        return WMFInterleaveResult(slots: slots, coinFlips: coinFlips, seed: seed, mergeVersion: mergeVersion)
    }

    /// One retriever's cursor over its own list. Its next item is the first item at or after the cursor whose page ID is not placed yet.
    private struct Picker<Item> {
        let searchType: WMFInterleaveSearchType
        let items: [Item]
        private let pageIDs: Set<Int>
        private var cursor = 0

        init(searchType: WMFInterleaveSearchType, items: [Item], pageIDs: Set<Int>) {
            self.searchType = searchType
            self.items = items
            self.pageIDs = pageIDs
        }

        func contains(_ id: Int) -> Bool {
            return pageIDs.contains(id)
        }

        mutating func nextIndex(placedPageIDs: Set<Int>, pageID: (Item) -> Int) -> Int? {
            while cursor < items.count && placedPageIDs.contains(pageID(items[cursor])) {
                cursor += 1
            }
            return cursor < items.count ? cursor : nil
        }
    }
}
