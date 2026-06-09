import Foundation
import Testing

struct NumberFormatterExtrasTests {

    struct ThousandsCase: Encodable, Sendable, CustomTestStringConvertible {
        let number: UInt64
        let expectedSubstring: String

        var testDescription: String {
            "\(number) contains \(expectedSubstring)"
        }

        static let all: [Self] = [
            ThousandsCase(number: 215, expectedSubstring: "215"),
            ThousandsCase(number: 1500, expectedSubstring: "1.5"),
            ThousandsCase(number: 538000, expectedSubstring: "538"),
            ThousandsCase(number: 867530939, expectedSubstring: "867.5"),
            ThousandsCase(number: 312490123456, expectedSubstring: "312.5")
        ]
    }

    @Test(arguments: ThousandsCase.all)
    func thousands(testCase: ThousandsCase) {
        let format = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: testCase.number))

        #expect(format.contains(testCase.expectedSubstring))
    }
}
