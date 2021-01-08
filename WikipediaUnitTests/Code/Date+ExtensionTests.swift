import XCTest

class Date_ExtensionTests: XCTestCase {

    func testBeforeAfter() throws {
        let currentDate = Date()
        let beforeDate = currentDate.addingTimeInterval(-100)
        let afterDate = currentDate.addingTimeInterval(100)

        // Date in past
        XCTAssert(beforeDate.isBefore(afterDate))
        XCTAssert(!beforeDate.isAfter(afterDate))

        XCTAssert(beforeDate.isBefore(afterDate, inclusive: true))
        XCTAssert(!beforeDate.isAfter(afterDate, inclusive: true))

        // Date in future
        XCTAssert(!afterDate.isBefore(beforeDate))
        XCTAssert(afterDate.isAfter(beforeDate))

        XCTAssert(!afterDate.isBefore(beforeDate, inclusive: true))
        XCTAssert(afterDate.isAfter(beforeDate, inclusive: true))

        // Inclusive cases
        XCTAssert(currentDate.isBefore(currentDate, inclusive: true))
        XCTAssert(currentDate.isAfter(currentDate, inclusive: true))

        XCTAssert(!currentDate.isAfter(currentDate))
        XCTAssert(!currentDate.isBefore(currentDate))
    }

    func testPicturePageTitle() throws {
        let currentDate = Date()
        guard let dateString = DateFormatter.wmf_englishHyphenatedYearMonthDay()?.string(from: currentDate) else {
            XCTFail("date string couldn't be produced")
            return
        }

        let properTitle = "Template:Potd/\(dateString)"

        XCTAssertEqual(properTitle, NSDate().wmf_picOfTheDayPageTitle())
    }

}
