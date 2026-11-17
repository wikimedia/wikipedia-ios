import XCTest
@testable import WMFData

final class WMFSplitMix64Tests: XCTestCase {

    func testOutputsMatchSharedVectors() throws {
        for vector in try WMFTeamDraftMergeVectors.load().splitmix64 {
            var random = WMFSplitMix64(seed: try XCTUnwrap(UInt64(vector.seed)))
            let outputs = vector.outputs.map { _ in String(random.nextUInt64()) }
            XCTAssertEqual(outputs, vector.outputs, "seed \(vector.seed)")
        }
    }

    func testCoinIsTopBitOfNextOutput() {
        var outputs = WMFSplitMix64(seed: 1234567)
        var coins = WMFSplitMix64(seed: 1234567)
        for _ in 0..<64 {
            XCTAssertEqual(Int(outputs.nextUInt64() >> 63), coins.nextCoin())
        }
    }
}
