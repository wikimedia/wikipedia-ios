import XCTest
@testable import Wikipedia

class WMFDatabaseHouseKeeperTests: XCTestCase {
    
    func testDaysBefore() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm ZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let housekeeper = WMFDatabaseHouseKeeper()
        
        guard let d1 = formatter.date(from: "2017/03/01 00:00 +0000") else {
            XCTFail()
            return
        }
        guard let d1_30 = housekeeper.daysBeforeDateInUTC(days: -30, date: d1) else {
            XCTFail()
            return
        }

        XCTAssertEqual("2017/01/28 00:00 +0000", formatter.string(from: d1_30));
    }
}
