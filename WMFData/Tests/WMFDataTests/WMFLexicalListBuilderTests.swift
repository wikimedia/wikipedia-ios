import XCTest
@testable import WMFData
import WMFDataMocks

/// Runs the lexical list vectors proposed in the stage 1 lexical list spec (mediawiki.org). The vectors were
/// produced by an independent reference implementation, not by `WMFLexicalListBuilder`.
final class WMFLexicalListBuilderTests: XCTestCase {

    private struct Vectors: Decodable {
        let lexicalVersion: Int
        let vectors: [Vector]

        enum CodingKeys: String, CodingKey {
            case lexicalVersion = "lexical_version"
            case vectors
        }
    }

    private struct Vector: Decodable {
        let name: String
        let fullTextThreshold: Int
        let prefix: [Int]
        let fullText: [Int]?
        let expected: [Int]

        enum CodingKeys: String, CodingKey {
            case name, prefix, expected
            case fullTextThreshold = "full_text_threshold"
            case fullText = "full_text"
        }
    }

    private func loadVectors() throws -> Vectors {
        let url = try XCTUnwrap(WMFDataMocksResources.url(forResource: "lexical_list_vectors"))
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    func testLexicalVersionMatchesVectors() throws {
        XCTAssertEqual(WMFLexicalListBuilder.lexicalVersion, try loadVectors().lexicalVersion)
    }

    func testBuildMatchesVectors() throws {
        let vectors = try loadVectors()
        XCTAssertFalse(vectors.vectors.isEmpty)
        for vector in vectors.vectors {
            let result = WMFLexicalListBuilder.build(prefix: vector.prefix, fullText: vector.fullText, fullTextThreshold: vector.fullTextThreshold) { $0 }
            XCTAssertEqual(result, vector.expected, vector.name)
        }
    }

    func testDefaultThresholdIsThirty() {
        XCTAssertEqual(WMFLexicalListBuilder.fullTextThreshold, 30)
    }
}
