import XCTest
import WMFDataMocks

/// The shared Team-Draft merge vectors, which Android also runs. The JSON is a verbatim copy of
/// `team_draft_merge_vectors.json` from apps-android-wikipedia (commit 748a0274f5feb19fd30fe39180290cf6160b9347).
/// Never edit or regenerate it here. TODO: decide a single canonical location for the vectors.
struct WMFTeamDraftMergeVectors: Decodable {
    let mergeVersion: Int
    let splitmix64: [SplitMix64Vector]
    let vectors: [MergeVector]

    enum CodingKeys: String, CodingKey {
        case mergeVersion = "merge_version"
        case splitmix64
        case vectors
    }

    struct SplitMix64Vector: Decodable {
        let seed: String
        let outputs: [String]
    }

    struct MergeVector: Decodable {
        let name: String
        let seed: String
        let listLength: Int
        let lexical: [Int]
        let semantic: [Int]
        let expected: ExpectedResult

        enum CodingKeys: String, CodingKey {
            case name, seed, lexical, semantic, expected
            case listLength = "list_length"
        }
    }

    struct ExpectedResult: Decodable {
        let coinFlips: String
        let slots: [ExpectedSlot]

        enum CodingKeys: String, CodingKey {
            case coinFlips = "coin_flips"
            case slots
        }
    }

    struct ExpectedSlot: Decodable, Equatable {
        let pageID: Int
        let team: String
        let rank: Int
        let alsoInOther: Bool

        enum CodingKeys: String, CodingKey {
            case pageID = "page_id"
            case team, rank
            case alsoInOther = "also_in_other"
        }
    }

    static func load() throws -> WMFTeamDraftMergeVectors {
        let url = try XCTUnwrap(WMFDataMocksResources.url(forResource: "team_draft_merge_vectors"))
        return try JSONDecoder().decode(WMFTeamDraftMergeVectors.self, from: Data(contentsOf: url))
    }
}
