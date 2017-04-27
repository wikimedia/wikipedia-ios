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
    
    func testReallyUnsupportedSyntax() {
        let format = "Box has {{sandwiches for everyone}}."
        let result = localizedString(withFormat: format, "12")
        XCTAssertEqual(result, "Box has .")
    }
    
    func testReallyReallyUnsupportedSyntax() {
        let format = "Box has {{}{{}{{{}}}."
        let result = localizedString(withFormat: format, "12")
        XCTAssertEqual(result, "Box has {{}{{}{.")
    }
    
    func testMultiple() {
        let format = "Box has {{PLURAL:$1|one egg|$1 eggs}} and {{PLURAL:$2|one sandwich|$2 sandwiches}}."
        let result = localizedString(withFormat: format, "12", "2")
        XCTAssertEqual(result, "Box has 12 eggs and 2 sandwiches.")
    }
    
    func testMoreThanOneOfSameSubstitution() {
        let format = "How many eggs does a box with {{PLURAL:$1|one egg|$1 eggs}} and {{PLURAL:$2|one sandwich|$2 sandwiches}} contain? {{PLURAL:$1|one egg|$1 eggs}}."
        let result = localizedString(withFormat: format, "12", "1")
        XCTAssertEqual(result, "How many eggs does a box with 12 eggs and one sandwich contain? 12 eggs.")
    }
}
