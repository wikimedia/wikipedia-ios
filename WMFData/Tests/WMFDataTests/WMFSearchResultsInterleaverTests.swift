import XCTest
@testable import WMFData

final class WMFSearchResultsInterleaverTests: XCTestCase {

    private func merge(_ lexical: [Int], _ semantic: [Int], listLength: Int, seed: UInt64) -> WMFInterleaveResult<Int> {
        return WMFSearchResultsInterleaver.merge(lexical: lexical, semantic: semantic, listLength: listLength, seed: seed) { $0 }
    }

    func testMergeVersionMatchesSharedVectors() throws {
        XCTAssertEqual(WMFSearchResultsInterleaver.mergeVersion, try WMFTeamDraftMergeVectors.load().mergeVersion)
    }

    func testMergeMatchesSharedVectors() throws {
        for vector in try WMFTeamDraftMergeVectors.load().vectors {
            let seed = try XCTUnwrap(UInt64(vector.seed), vector.name)
            let result = merge(vector.lexical, vector.semantic, listLength: vector.listLength, seed: seed)
            let slots = result.slots.map {
                WMFTeamDraftMergeVectors.ExpectedSlot(pageID: $0.item, team: $0.searchType.rawValue, rank: $0.rank, alsoInOther: $0.alsoInOther)
            }
            XCTAssertEqual(result.coinFlipsLog, vector.expected.coinFlips, vector.name)
            XCTAssertEqual(slots, vector.expected.slots, vector.name)
            XCTAssertEqual(result.seedLog, vector.seed, vector.name)
        }
    }

    func testMergeIsDeterministicForSameInputs() {
        let lexical = [1, 2, 3, 4, 5]
        let semantic = [3, 6, 1, 7, 8]
        let seed = WMFSearchResultsInterleaver.newSeed()
        XCTAssertEqual(
            merge(lexical, semantic, listLength: 8, seed: seed),
            merge(lexical, semantic, listLength: 8, seed: seed)
        )
    }

    func testEachRetrieverPicksFirstAboutHalfTheTime() {
        let lexical = Array(1...10)
        let semantic = Array(101...110)
        let listLength = 10
        let runs = 100_000
        var lexicalCountByPosition = [Int](repeating: 0, count: listLength)
        var lexicalFirstFlips = 0
        var totalFlips = 0

        for seed in 0..<UInt64(runs) {
            let result = merge(lexical, semantic, listLength: listLength, seed: seed)
            lexicalFirstFlips += result.coinFlips.filter { $0 == .lexical }.count
            totalFlips += result.coinFlips.count
            for (position, slot) in result.slots.enumerated() where slot.searchType == .lexical {
                lexicalCountByPosition[position] += 1
            }
        }

        assertShareIsBalanced("lexical-first share", Double(lexicalFirstFlips) / Double(totalFlips))
        for (position, count) in lexicalCountByPosition.enumerated() {
            assertShareIsBalanced("lexical share at position \(position)", Double(count) / Double(runs))
        }
    }

    private func assertShareIsBalanced(_ label: String, _ share: Double) {
        XCTAssertTrue((0.49...0.51).contains(share), "\(label) was \(share)")
    }
}
