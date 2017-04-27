import XCTest

class LocalizationTest: XCTestCase {
    
    func testSingular() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "1")
        XCTAssertEqual(result, "Undelete one edit")
    }
    
    func testPlural() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "2")
        XCTAssertEqual(result, "Undelete 2 edits")
    }
    
    func testZero() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "0")
        XCTAssertEqual(result, "Undelete 0 edits")
    }
    
    func testThousands() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "1,000,000")
        XCTAssertEqual(result, "Undelete 1,000,000 edits")
    }
    
    func testDecimal() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "1,000,000.00")
        XCTAssertEqual(result, "Undelete 1,000,000.00 edits")
    }
    
    func testDecimalOne() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "1.00")
        XCTAssertEqual(result, "Undelete one edit")
    }
    
    func testDecimalOnePointFourNine() {
        let format = "Undelete {{PLURAL:$1|one edit|$1 edits}}"
        let result = localizedString(withFormat: format, "1.49")
        XCTAssertEqual(result, "Undelete 1.49 edits")
    }
    
    func testUnsupportedSyntax() {
        let format = "Box has {{PLURAL:$1|one egg|$1 eggs|12=a dozen eggs}}."
        let result = localizedString(withFormat: format, "12")
        XCTAssertEqual(result, "Box has 12 eggs.")
    }
}
