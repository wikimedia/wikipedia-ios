//
//  CommonHelpers.swift
//  WikipediaUITests
//
//  Created by Eugene Tkachenko on 22.10.2022.
//

import XCTest


public class CommonHelpers {

}

public func waitForElement(
    _ element: XCUIElement,
    toExist: Bool = true,
    timeOut: Double = 30,
    assertMessage: String? = nil,
    elementName: String? = nil
) {
    let predicate = NSPredicate(format: "exists == \(toExist)")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    
    waitForPredicate(
        expectation,
        timeOut: timeOut,
        elementName: elementName ?? "\(element)",
        condition: toExist ? "to exist" : "to not exist",
        assertMessage: assertMessage
    )
}

public func waitForHittable(
    _ element: XCUIElement,
    hittable: Bool = true,
    timeOut: Double = 30,
    elementName: String? = nil
) {
    let predicate = NSPredicate(format: "hittable == \(hittable)")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    
    waitForPredicate(
        expectation,
        timeOut: timeOut,
        elementName: elementName ?? "\(element)",
        condition: hittable ? "to be hittable" : "to not be hittable"
    )
}

public func waitForCount(
    _ query: XCUIElementQuery,
    count: Int,
    timeOut: Double = 30,
    assertMessage: String? = nil,
    elementName: String? = nil
) {
    let predicate = NSPredicate(format: "count == \(count)")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: query)
    
    waitForPredicate(
        expectation,
        timeOut: timeOut,
        elementName: elementName ?? "\(query)",
        condition: "count to be \(count)",
        assertMessage: assertMessage
    )
}

private func waitForPredicate(
    _ expectation: XCTNSPredicateExpectation,
    timeOut: Double,
    elementName: String,
    condition: String,
    assertMessage: String? = nil
) {
    let result = XCTWaiter().wait(for: [expectation], timeout: timeOut)
    XCTAssertTrue(
        result == .completed,
        assertMessage ?? "Wait for element `\(elementName)` \(condition) timed out after \(timeOut) seconds."
    )
}
