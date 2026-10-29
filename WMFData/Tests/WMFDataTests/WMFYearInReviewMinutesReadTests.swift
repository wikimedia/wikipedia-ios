import XCTest
@testable import WMFData

/// Covers the rules of the minutes read slide that are shared with Android: the eligibility range and the
/// comparison for each threshold of the shared copy spreadsheet.
final class WMFYearInReviewMinutesReadTests: XCTestCase {

    private typealias Comparison = WMFYearInReviewMinutesReadComparison

    private func readData(minutesRead: Int) throws -> WMFYearInReviewReadData {
        let data = try JSONSerialization.data(withJSONObject: ["readCount": 10, "minutesRead": minutesRead])
        return try JSONDecoder().decode(WMFYearInReviewReadData.self, from: data)
    }

    func testLessThanOneMinuteIsNotEligible() throws {
        XCTAssertFalse(try readData(minutesRead: 0).isMinutesReadEligible)
        XCTAssertTrue(try readData(minutesRead: 1).isMinutesReadEligible)
    }

    func testMoreThanThreeHundredThousandMinutesIsNotEligible() throws {
        XCTAssertTrue(try readData(minutesRead: 300_000).isMinutesReadEligible)
        XCTAssertFalse(try readData(minutesRead: 300_001).isMinutesReadEligible)
    }

    func testNoComparisonForLessThanOneMinute() {
        XCTAssertNil(Comparison.comparison(forMinutes: 0))
    }

    func testEachThresholdShowsItsComparison() {
        let expected: [(Int, Comparison)] = [
            (1, .hummingbird), (8, .hummingbird),
            (9, .sunlight), (12, .sunlight),
            (13, .egg), (18, .egg),
            (19, .fallAsleep), (30, .fallAsleep),
            (31, .sitcom), (92, .sitcom),
            (93, .spaceStation), (120, .spaceStation),
            (121, .marathon), (539, .marathon),
            (540, .nightSleep), (1440, .nightSleep),
            (1441, .honeybee), (2799, .honeybee)
        ]
        for (minutes, comparison) in expected {
            XCTAssertEqual(Comparison.comparison(forMinutes: minutes), comparison, "\(minutes) minutes")
        }
    }

    func testTheDaysComparisonRoundsDownAndStopsAtThreeHundredDays() {
        XCTAssertEqual(Comparison.comparison(forMinutes: 2800), .days(1))
        XCTAssertEqual(Comparison.comparison(forMinutes: 2880), .days(2))
        XCTAssertEqual(Comparison.comparison(forMinutes: 300_000), .days(208))
        XCTAssertEqual(Comparison.comparison(forMinutes: 1_000_000), .days(300))
    }
}
