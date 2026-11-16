import Foundation
import Testing
@testable import WMFData

struct WMFSemanticSearchInterleavedListTests {

    private let seed: UInt64 = 42

    @Test
    func aFailedSemanticRequestLeavesTheLexicalListCutToTheListLength() {
        let prefix = Array(1...10)
        let result = WMFSemanticSearchInterleavedList.build(prefix: prefix, fullText: nil, semantic: .failed, seed: seed)

        #expect(result.items.map(\.pageID) == prefix)
        #expect(result.items.allSatisfy { $0.source == .lexicalPrefix })
        #expect(result.merge == nil)
        #expect(result.state == .lexicalOnlyError)
    }

    @Test
    func eachSemanticFailureHasItsOwnState() {
        let timedOut = WMFSemanticSearchInterleavedList.build(prefix: [1, 2], fullText: nil, semantic: .timedOut, seed: seed)
        let failed = WMFSemanticSearchInterleavedList.build(prefix: [1, 2], fullText: nil, semantic: .failed, seed: seed)
        let rateLimited = WMFSemanticSearchInterleavedList.build(prefix: [1, 2], fullText: nil, semantic: .rateLimited, seed: seed)

        #expect(timedOut.state == .lexicalOnlyTimeout)
        #expect(failed.state == .lexicalOnlyError)
        #expect(rateLimited.state == .lexicalOnlyRateLimited)
        #expect([timedOut, failed, rateLimited].allSatisfy { $0.items.map(\.pageID) == [1, 2] && $0.merge == nil })
    }

    @Test
    func fullTextOnlyTopsUpAShortPrefixList() {
        let full = WMFSemanticSearchInterleavedList.build(prefix: Array(1...10), fullText: Array(11...20), semantic: .failed, seed: seed)
        #expect(full.items.map(\.pageID) == Array(1...10), "A prefix list that fills the threshold is not topped up")

        let short = WMFSemanticSearchInterleavedList.build(prefix: [1, 2, 3], fullText: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12], semantic: .failed, seed: seed)
        #expect(short.items.map(\.pageID) == Array(1...10))
        #expect(short.items.prefix(3).allSatisfy { $0.source == .lexicalPrefix })
        #expect(short.items.dropFirst(3).allSatisfy { $0.source == .lexicalFullText })
    }

    @Test
    func mergedListHasTheListLengthAndEachPageOnce() {
        let result = WMFSemanticSearchInterleavedList.build(prefix: Array(1...10), fullText: nil, semantic: .results(Array(101...110)), seed: seed)

        #expect(result.items.count == WMFSemanticSearchInterleavedConfiguration.listLength)
        #expect(Set(result.items.map(\.pageID)).count == result.items.count)
        #expect(result.items.filter { $0.source == .semantic }.count == 5)
        #expect(result.items.filter { $0.source == .lexicalPrefix }.count == 5)
        #expect(result.merge != nil)
        #expect(result.state == .full)
    }

    @Test
    func aPageInBothListsAppearsOnce() {
        let result = WMFSemanticSearchInterleavedList.build(prefix: Array(1...10), fullText: nil, semantic: .results(Array(1...10)), seed: seed)

        #expect(result.items.count == 10)
        #expect(Set(result.items.map(\.pageID)) == Set(1...10))
    }

    @Test
    func theSameSeedGivesTheSameList() {
        let first = WMFSemanticSearchInterleavedList.build(prefix: Array(1...10), fullText: nil, semantic: .results(Array(101...110)), seed: seed)
        let second = WMFSemanticSearchInterleavedList.build(prefix: Array(1...10), fullText: nil, semantic: .results(Array(101...110)), seed: seed)

        #expect(first.items == second.items)
    }

    @Test
    func semanticReturningNothingLeavesTheLexicalListAndItsOwnState() {
        let result = WMFSemanticSearchInterleavedList.build(prefix: Array(1...10), fullText: nil, semantic: .results([]), seed: seed)

        #expect(result.items.map(\.pageID) == Array(1...10))
        #expect(result.items.allSatisfy { $0.source == .lexicalPrefix })
        #expect(result.state == .lexicalOnlyEmpty)
    }

    @Test
    func lexicalReturningNothingLeavesTheSemanticList() {
        let result = WMFSemanticSearchInterleavedList.build(prefix: [], fullText: nil, semantic: .results([5, 6, 7]), seed: seed)

        #expect(result.items.map(\.pageID) == [5, 6, 7])
        #expect(result.items.allSatisfy { $0.source == .semantic })
        #expect(result.state == .semanticOnly)
    }

    @Test
    func bothReturningNothingIsAnEmptyListWithTheNoneState() {
        let result = WMFSemanticSearchInterleavedList.build(prefix: [], fullText: nil, semantic: .results([]), seed: seed)

        #expect(result.items.isEmpty)
        #expect(result.state == WMFSemanticSearchInterleaveState.none)
    }

    @Test
    func aSemanticFailureWithNoLexicalResultsIsAnEmptyListThatKeepsTheFailureState() {
        let result = WMFSemanticSearchInterleavedList.build(prefix: [], fullText: nil, semantic: .timedOut, seed: seed)

        #expect(result.items.isEmpty)
        #expect(result.state == .lexicalOnlyTimeout)
    }
}
