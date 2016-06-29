//
//  WMFBackgroundTestManagerTests.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 7/7/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

@testable import Wikipedia
import PromiseKit

// Must start task numbers at 1, as 0 == invalid
let defaultInitialTask = 1

var currentTask = defaultInitialTask
var expirationHandlers: [(()->Void)] = []
var stoppedTasks: [Int] = []

/**
 * Mock of background task manager that allows for testing of start/stop/expiration cases by replacing UIApplication
 * calls with our own.
 */
public class WMFMockedBackgroundTaskManager<T> : WMFBackgroundTaskManager<T> {
    public required init(next: () -> T?,
                         processor: (T) -> Promise<Void>,
                         finalize: () -> Promise<Void>,
                         queue: dispatch_queue_t = dispatch_get_global_queue(0, 0)) {
        super.init(next: next, processor: processor, finalize: finalize, queue: queue)
    }

    // Instead of starting a background task, increment our task counter and store the expiration handler for later.
    override class func startTask(expirationHandler: () -> Void) -> UIBackgroundTaskIdentifier {
        expirationHandlers.append(expirationHandler)
        currentTask += 1
        return currentTask
    }

    // Instead of stopping a task, store it as a task that we would have stopped.
    override class func stopTask(task: UIBackgroundTaskIdentifier) {
        stoppedTasks.append(task)
    }
}

@objc
class WMFBackgroundTaskManagerTests : WMFAsyncTestCase {
    var didFinalize: Bool = false

    override func setUp() {
        didFinalize = false
        stoppedTasks.removeAll()
        currentTask = defaultInitialTask
        expirationHandlers.removeAll()
        super.setUp()
    }

    // MARK: - Resolution

    func testResolvesWhenNextReturnsNil() {
        let taskMgr = WMFMockedBackgroundTaskManager(
        next: {
            return nil
        },
        processor: { (dummy: String) in
            XCTFail("Processor should not have been called if returned object is nil")
            return Promise()
        },
        finalize: self.markAsFinalized)
        expectPromise(toResolve(),
        pipe: {
            XCTAssertEqual(currentTask, defaultInitialTask, "Should not have started a task")
            XCTAssertEqual(stoppedTasks, [], "Should not have stopped any tasks")
            XCTAssertTrue(self.didFinalize, "Expected finalize function to be called")
        },
        test: { () -> Promise<Void> in
            taskMgr.start()
        })
    }

    func testResolvesWhenNextReturnsNilAfterReturningNonNilValues() {
        var items = Array(0...10)
        var processedItems: [Int] = []
        let expectedItems = Array(items.reverse())
        let taskMgr = WMFMockedBackgroundTaskManager(
        next: { () -> Int? in
            let item: Int? = items.count > 0 ? items.removeLast() : nil
            return item
        },
        processor: { (item: Int) -> Promise<Void> in
            return dispatch_promise(on: dispatch_get_main_queue()) { () -> Void in
                processedItems.append(item)
            }
        },
        finalize: self.markAsFinalized)

        expectPromise(toResolve(),
        pipe: {
            XCTAssertTrue(self.didFinalize)
            XCTAssertTrue(items.isEmpty, "Expected all items to be popped from input array, but was \(items)")
            XCTAssertEqual(processedItems, expectedItems, "Expected to process all input items")
            self.verifyExpectedNumberOfStartedAndStoppedBackgroundTasks(expectedItems.count)
        },
        test: { () -> Promise<Void> in
            taskMgr.start()
        })
    }

    // MARK: - Rejection

    func testRejectsWithoutProcessingFurtherItemsWhenRejected() {
        var items: [AnyObject] = Array(1...10)
        let errIndex = 5
        items.insert(NSError(domain: "OH NO", code: 0, userInfo: nil), atIndex: errIndex)
        var processedItems: [Int] = []
        let expectedItems: [Int] = Array(items.reverse()[0...errIndex - 1].map({ $0 as! Int }))

        let taskMgr = WMFMockedBackgroundTaskManager(
        next: { () -> AnyObject? in
            return items.count > 0 ? items.removeLast() : nil
        },
        processor: { (item: AnyObject) -> Promise<Void> in
            return dispatch_promise(on: dispatch_get_main_queue()) { () throws -> Void in
                guard item is Int else {
                    throw item as! NSError
                }
                return processedItems.append(item as! Int)
            }
        },
        finalize: self.markAsFinalized)

        expectPromise(toReport(),
        pipe: { _ -> Void in
            XCTAssertTrue(self.didFinalize)
            XCTAssertEqual(processedItems, expectedItems, "Expected to process items until error was encountered")
            // add one to expected number of tasks to account for error
            self.verifyExpectedNumberOfStartedAndStoppedBackgroundTasks(expectedItems.count + 1)
        },
        test: { () -> Promise<Void> in
            taskMgr.start()
        })
    }

    func testRejectsAfterTaskIsExpired() {
        var items = Array(0...10)
        let indexOfItemToExpire = 5
        let itemToExpire = items[indexOfItemToExpire]
        var processedItems: [Int] = []
        let expectedItems = Array(items.reverse()[0...items.count - indexOfItemToExpire - 1])

        let taskMgr = WMFMockedBackgroundTaskManager(
        next: { () -> Int? in
            return items.count > 0 ? items.removeLast() : nil
        },
        processor: { (item: Int) -> Promise<Void> in
            // since processing happens before expiration, it must be included in our count
            processedItems.append(item)
            if item == itemToExpire {
                expirationHandlers.last!()
            }
            return Promise()
        },
        finalize: self.markAsFinalized)

        expectPromise(toReport(ErrorPolicy.AllErrors),
        pipe: { err -> Void in
            XCTAssertTrue(self.didFinalize)
            XCTAssertTrue((err as! CancellableErrorType).cancelled, "Expected cancelled error when task expires")
            XCTAssertEqual(processedItems, expectedItems, "Expected to process up to and including expired item")
            self.verifyExpectedNumberOfStartedAndStoppedBackgroundTasks(expectedItems.count)
        },
        test: { () -> Promise<Void> in
            taskMgr.start()
        })
    }

    func testRejectsImmediatelyWhenGivenInvalidTaskId() {
        currentTask = UIBackgroundTaskInvalid
        let taskMgr = WMFMockedBackgroundTaskManager(
        next: {
            return "Foo"
        },
        processor: { (dummy: String) in
            XCTFail("Processor should not have been called if the provided task identifier was invalid")
            return Promise()
        },
        finalize: self.markAsFinalized)

        expectPromise(toReport(ErrorPolicy.AllErrors),
        pipe: { err -> Void in
            guard case BackgroundTaskError.InvalidTask = err else {
                XCTFail("Expected invalid task error, but got \(err)")
                return
            }
            XCTAssertTrue(self.didFinalize)
            XCTAssertEqual(stoppedTasks, [], "Should not have stopped any tasks")
        },
        test: { () -> Promise<Void> in
            taskMgr.start()
        })
    }

    // MARK: - Utils

    func markAsFinalized() -> Promise<Void> {
        return Promise().thenInBackground() {
            self.didFinalize = true
        }
    }

    func verifyExpectedNumberOfStartedAndStoppedBackgroundTasks(expectedNumberOfTasks: Int) {
        // task identifiers start at 1, so the counter should be at the expected number of tasks + 1
        XCTAssertEqual(currentTask, expectedNumberOfTasks + 1)
        // since we should stop every task before starting the next, the stoppedTasks should contain all tasks up to
        // but not including the current one
        XCTAssertEqual(stoppedTasks, Array(1...expectedNumberOfTasks))
    }
}
