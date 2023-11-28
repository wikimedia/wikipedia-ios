import Foundation
import UIKit
import XCTest

class CollectionAsyncMapTests: XCTestCase {

    func testAsyncMapResultsAreMappedToCorrectItemsEvenIfReceivedOutOfOrder() {
        let expectation = XCTestExpectation(description: "maps results received out of order correctly")
        
        let inputItems = ["THIS", "THAT", "OTHER"]
        let expectedOutputItems = ["THIS result", "THAT result", "OTHER result"]
        
        let asyncItemTransformer = { (item: String, completion: @escaping (String) -> Void) in
            // fake out a process which takes 'item' and asynchronously gets a result for it
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) { // use random delay to ensure results map to correct items even if results are received out of (collection) order
                let resultForItem = "\(item) result"
                completion(resultForItem)
            }
        }

        let completionHandler: ([String]) -> Void = { results in
            XCTAssertEqual(results, expectedOutputItems)
            expectation.fulfill()
        }
        inputItems.asyncMap(asyncItemTransformer, completion: completionHandler)
        wait(for:[expectation], timeout: 5, enforceOrder: true)
    }

    func testAsyncCompactMapResultsAreMappedToCorrectItemsEvenIfReceivedOutOfOrder() {
        let expectation = XCTestExpectation(description: "maps results received out of order correctly (even when compacting)")
        
        let inputItems = ["THIS", "MAP_TO_NIL", "THAT", "MAP_TO_NIL", "OTHER"]
        let expectedOutputItems = ["THIS result", "THAT result", "OTHER result"]
        
        let asyncItemTransformer = { (item: String, completion: @escaping (String?) -> Void) in
            // fake out a process which takes 'item' and asynchronously gets a result for it
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) { // use random delay to ensure results map to correct items even if results are received out of (collection) order
                guard item != "MAP_TO_NIL" else { // fake out getting nil for some items
                    completion(nil)
                    return
                }
                let resultForItem = "\(item) result"
                completion(resultForItem)
            }
        }
        
        let completionHandler: ([String]) -> Void = { results in
            XCTAssertEqual(results, expectedOutputItems)
            expectation.fulfill()
        }
        inputItems.asyncCompactMap(asyncItemTransformer, completion: completionHandler)
        wait(for:[expectation], timeout: 5, enforceOrder: true)
    }

    func testAsyncForEachPerformsBlockForEachItem() {
        let expectation = XCTestExpectation(description: "block performed for each object")
        
        let inputItems = ["THIS", "THAT", "OTHER"]
        
        // use Sets because `asyncForEach` does no mapping, so order isn't important
        let expectedResults = Set(arrayLiteral: "THIS", "OTHER", "THAT")
        var results:Set<String> = []
        let semaphore = DispatchSemaphore(value: 1)
        let asyncItemBlock = { (item: String, completion: @escaping () -> Void) in
            // fake out a process which takes 'item' and asynchronously performs a block with it
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) { // use random delay to more closely simulate read async usage
                semaphore.wait()
                results.insert(item)
                semaphore.signal()
                completion()
            }
        }
        
        let completionHandler: () -> Void = {
            XCTAssertEqual(results, expectedResults)
            expectation.fulfill()
        }
        inputItems.asyncForEach(asyncItemBlock, completion: completionHandler)
        wait(for:[expectation], timeout: 5, enforceOrder: true)
    }
    
    func testAsyncMapToDictionary() {
        let expectation = XCTestExpectation(description: "wait for notification")
        
        let input = ["A", "B", "C", "D", "E", "F", "G", "H"]
        let expectedOutput = ["A":"a", "B":"b", "C":"c", "D":"d", "E":"e", "F":"f", "G":"g", "H":"h"]
        
        input.asyncMapToDictionary(block: { (input, completion) in
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                completion(input, input.lowercased())
            }
        }, queue: DispatchQueue.main) { (output) in
            XCTAssert(Thread.isMainThread)
            XCTAssertEqual(output, expectedOutput, "Result of asyncMapToDictionary not the same as the expected")
            expectation.fulfill()
        }
        
        wait(for:[expectation], timeout: 5, enforceOrder: true)
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
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 0 ... 500))) {
                completion(input, transform(input))
            }
        }, queue: DispatchQueue.main) { (output) in
            XCTAssert(Thread.isMainThread)
            XCTAssertEqual(output, expectedOutput, "Result of asyncMapToDictionary not the same as the expected")
            expectation.fulfill()
        }
        
        wait(for:[expectation], timeout: 5, enforceOrder: true)
    }
    
    func testLargeAsyncMap() {
        let randomDelayBlock: (String, @escaping (String) -> Void) -> Void = { (string, completion) in
            let randomMillisecondDelay = DispatchTimeInterval.milliseconds(Int.random(in: 1...10))
            let time = DispatchTime.now() + randomMillisecondDelay
            DispatchQueue.global(qos: .default).asyncAfter(deadline: time) {
                completion(string)
            }
            
        }
        let count = 1000
        var identifiers: [String] = []
        identifiers.reserveCapacity(count)
        for _ in 1...count {
            identifiers.append(UUID().uuidString)
        }
        let expectation = XCTestExpectation(description: "wait for completion")
        identifiers.asyncMap(randomDelayBlock) { (processedIdentifiers) in
            XCTAssert(processedIdentifiers == identifiers)
            expectation.fulfill()
        }
        wait(for:[expectation], timeout: 5, enforceOrder: true)
    }
    
    func testLargeAsyncCompactMap() {
        let randomDelayBlock: (String, @escaping (String?) -> Void) -> Void = { (string, completion) in
            let randomMillisecondDelay = DispatchTimeInterval.milliseconds(Int.random(in: 1...10))
            let time = DispatchTime.now() + randomMillisecondDelay
            DispatchQueue.global(qos: .default).asyncAfter(deadline: time) {
                completion(string.hasPrefix("A") ? nil : string)
            }
            
        }
        let count = 1000
        var identifiers: [String] = []
        identifiers.reserveCapacity(count)
        for _ in 1...count {
            identifiers.append(UUID().uuidString)
        }
        let expectation = XCTestExpectation(description: "wait for completion")
        identifiers.asyncCompactMap(randomDelayBlock) { (processedIdentifiers) in
            XCTAssert(processedIdentifiers.filter { $0.hasPrefix("A") }.isEmpty)
            expectation.fulfill()
        }
        wait(for:[expectation], timeout: 5, enforceOrder: true)
    }
    
}
