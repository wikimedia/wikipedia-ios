import XCTest
import WMF

class WMFDatabaseHouseKeeperTests: XCTestCase {
    
    func testDaysBefore() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm ZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        localFormatter.timeZone = TimeZone.current

        guard let d1 = localFormatter.date(from: "2017/03/01 00:00") as NSDate? else {
            XCTFail()
            return
        }
        
        guard let d1_30 = d1.wmf_midnightUTCDateFromLocalDate(byAddingDays:-30) else {
            XCTFail()
            return
        }
        XCTAssertEqual("2017/01/30 00:00 +0000", formatter.string(from: d1_30));
    
        guard let d1_1 = d1.wmf_midnightUTCDateFromLocalDate(byAddingDays:-1) else {
            XCTFail()
            return
        }
        XCTAssertEqual("2017/02/28 00:00 +0000", formatter.string(from: d1_1));
        
        guard let d1_plus1 = d1.wmf_midnightUTCDateFromLocalDate(byAddingDays:1) else {
            XCTFail()
            return
        }
        XCTAssertEqual("2017/03/02 00:00 +0000", formatter.string(from: d1_plus1));
    }
}
