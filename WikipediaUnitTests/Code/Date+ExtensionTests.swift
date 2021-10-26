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

    /// Note that this test requires the device to be set to `en-us` to pass: https://phabricator.wikimedia.org/T259859
    func testShortDateStringFormatterForNotifications() {
        let testDateComponents = DateComponents(year: 2021, month: 10, day: 20, hour: 0, minute: 0, second: 0)
        let testDate = Calendar.current.date(from: testDateComponents)!

        // Setup test dates
        let oneMinuteAgoDate = Calendar.current.date(byAdding: DateComponents(minute: -1), to: testDate)! as NSDate
        let thirtyMinutesAgoDate = Calendar.current.date(byAdding: DateComponents(minute: -30), to: testDate)! as NSDate
        let oneHourAgoDate = Calendar.current.date(byAdding: DateComponents(hour: -1), to: testDate)! as NSDate
        let tenHoursAgoDate = Calendar.current.date(byAdding: DateComponents(hour: -10), to: testDate)! as NSDate
        let twentyFourHoursAgoDate = Calendar.current.date(byAdding: DateComponents(hour: -24), to: testDate)! as NSDate
        let oneDayAgoDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: testDate)! as NSDate
        let oneMonthAgoDate = Calendar.current.date(byAdding: DateComponents(month: -1), to: testDate)! as NSDate
        let futureDate = Calendar.current.date(byAdding: DateComponents(month: 1), to: testDate)! as NSDate

        XCTAssertEqual((testDate as NSDate).wmf_localizedShortDateStringRelative(to: testDate), "Now")
        XCTAssertEqual(oneMinuteAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "1 min ago")
        XCTAssertEqual(thirtyMinutesAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "30 mins ago")
        XCTAssertEqual(oneHourAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "1 hr ago")
        XCTAssertEqual(tenHoursAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "10 hrs ago")
        XCTAssertEqual(twentyFourHoursAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "10/19/21")
        XCTAssertEqual(oneDayAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "10/19/21")
        XCTAssertEqual(oneMonthAgoDate.wmf_localizedShortDateStringRelative(to: testDate), "9/20/21")
        XCTAssertEqual(futureDate.wmf_localizedShortDateStringRelative(to: testDate), "11/20/21")
    }

}
