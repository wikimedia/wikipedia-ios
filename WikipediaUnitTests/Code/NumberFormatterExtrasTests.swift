import XCTest

class NumberFormatterExtrasTests: XCTestCase {
    
    func testThousands() {
        var number: UInt64 = 215
        var format: String = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: number as UInt64))
        XCTAssertTrue(format.contains("215"))
        
        number = 1500
        format = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: number as UInt64))
        XCTAssertTrue(format.contains("1.5"))
        
        number = 538000
        format = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: number as UInt64))
        XCTAssertTrue(format.contains("538"))
        
        number = 867530939
        format = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: number as UInt64))
        XCTAssertTrue(format.contains("867.5"))
        
        number = 312490123456
        format = NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: number as UInt64))
        XCTAssertTrue(format.contains("312.5"))
    }
    
}
