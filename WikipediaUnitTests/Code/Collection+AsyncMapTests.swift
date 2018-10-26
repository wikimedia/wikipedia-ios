import Foundation
import UIKit
import XCTest

class CollectionAsyncMapTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testAsyncMapResultsAreMappedToCorrectItemsEvenIfReceivedOutOfOrder() {
        let expectation = XCTestExpectation(description: "maps results received out of order correctly")
        
        let inputItems = ["THIS", "THAT", "OTHER"]
        let expectedOutputItems = ["THIS result", "THAT result", "OTHER result"]
        
        let asyncItemTransformer = { (item: String, completion: @escaping (String) -> Void) in
            // fake out a process which takes 'item' and asynchronously gets a result for it
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .seconds(Int.random(in: 0 ... 3))) { // use random delay to ensure results map to correct items even if results are received out of (collection) order
                let resultForItem = "\(item) result"
                completion(resultForItem)
            }
        }

        let completionHandler: ([String]) -> Void = { results in
            if results == expectedOutputItems {
                expectation.fulfill()
            }
        }
        inputItems.asyncMap(asyncItemTransformer, completion: completionHandler)
        wait(for:[expectation], timeout: 4, enforceOrder: true)
    }

    func testAsyncCompactMapResultsAreMappedToCorrectItemsEvenIfReceivedOutOfOrder() {
        let expectation = XCTestExpectation(description: "maps results received out of order correctly (even when compacting)")
        
        let inputItems = ["THIS", "MAP_TO_NIL", "THAT", "MAP_TO_NIL", "OTHER"]
        let expectedOutputItems = ["THIS result", "THAT result", "OTHER result"]
        
        let asyncItemTransformer = { (item: String, completion: @escaping (String?) -> Void) in
            // fake out a process which takes 'item' and asynchronously gets a result for it
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .seconds(Int.random(in: 0 ... 3))) { // use random delay to ensure results map to correct items even if results are received out of (collection) order
                guard item != "MAP_TO_NIL" else { // fake out getting nil for some items
                    completion(nil)
                    return
                }
                let resultForItem = "\(item) result"
                completion(resultForItem)
            }
        }
        
        let completionHandler: ([String]) -> Void = { results in
            if results == expectedOutputItems {
                expectation.fulfill()
            }
        }
        inputItems.asyncCompactMap(asyncItemTransformer, completion: completionHandler)
        wait(for:[expectation], timeout: 4, enforceOrder: true)
    }
    
    func testAsyncMapToDictionary() {
        let expectation = XCTestExpectation(description: "wait for notification")
        
        let input = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let expectedOutput = ["A":"a", "B":"b", "C":"c", "D":"d", "E":"e", "F":"f", "G":"g", "H":"h"]
        
        input.asyncMapToDictionary(block: { (input, completion) in
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .seconds(Int.random(in: 0 ... 3))) {
                completion(input, input.lowercased())
            }
        }, queue: DispatchQueue.main) { (output) in
            XCTAssert(Thread.isMainThread)
            XCTAssertEqual(output, expectedOutput, "Result of asyncMapToDictionary not the same as the expected")
            expectation.fulfill()
        }
        
        wait(for:[expectation], timeout: 10, enforceOrder: true)
    }
    
    
    func testAsyncMapToDictionaryWithLargeInput() {
        let expectation = XCTestExpectation(description: "wait for notification")
        
        let count = 10000
        var input = [Int]()
        input.reserveCapacity(count)
        var expectedOutput = [Int:Int]()
        expectedOutput.reserveCapacity(count)
        let transform = { (i: Int) in return i * i }
        for i in 1...count {
            input.append(i)
            expectedOutput[i] = transform(i)
        }
        
        input.asyncMapToDictionary(block: { (input, completion) in
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .seconds(Int.random(in: 0 ... 3))) {
                completion(input, transform(input))
            }
        }, queue: DispatchQueue.main) { (output) in
            XCTAssert(Thread.isMainThread)
            XCTAssertEqual(output, expectedOutput, "Result of asyncMapToDictionary not the same as the expected")
            expectation.fulfill()
        }
        
        wait(for:[expectation], timeout: 10, enforceOrder: true)
    }
}
