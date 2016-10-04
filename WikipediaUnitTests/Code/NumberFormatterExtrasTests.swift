import XCTest

class NumberFormatterExtrasTests: XCTestCase {
    
    func testThousands() {
        var number = 215
        var format = NSNumberFormatter.localizedThousandsStringFromNumber(number)
        XCTAssertTrue(format.containsString("215"))
        
        number = 1500
        format = NSNumberFormatter.localizedThousandsStringFromNumber(number)
        XCTAssertTrue(format.containsString("1.5"))
        
        number = 538000
        format = NSNumberFormatter.localizedThousandsStringFromNumber(number)
        XCTAssertTrue(format.containsString("538"))
        
        number = 867530939
        format = NSNumberFormatter.localizedThousandsStringFromNumber(number)
        XCTAssertTrue(format.containsString("867.5"))
        
        number = 312490123456
        format = NSNumberFormatter.localizedThousandsStringFromNumber(number)
        XCTAssertTrue(format.containsString("312.5"))
    }
    
}
