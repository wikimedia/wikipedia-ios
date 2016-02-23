//
//  WMFImageControllerCancellationTests.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 8/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import UIKit
import XCTest
@testable import Wikipedia
import PromiseKit
import Nocilla
import Nimble

class WMFImageControllerTests: XCTestCase {
    private typealias ImageDownloadPromiseErrorCallback = (Promise<WMFImageDownload>) -> ((ErrorType) -> Void) -> Void

    var imageController: WMFImageController!

    override func setUp() {
        super.setUp()
        imageController = WMFImageController.temporaryController()
    }

    override func tearDown() {
        super.tearDown()
        // might have been set to nil in one of the tests. delcared as implicitly unwrapped for convenience
        imageController?.deleteAllImages()
        LSNocilla.sharedInstance().stop()
    }

    // MARK: - Simple fetching

    func testReceivingDataResponseResolves() {
        let testURL = NSURL(string: "https://upload.wikimedia.org/foo@\(UInt(UIScreen.mainScreen().scale))x.png")!
        let testImage = UIImage(named: "image-placeholder")!
        let stubbedData = UIImagePNGRepresentation(testImage)

        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString).andReturnRawResponse(stubbedData)

        expectPromise(toResolve(),
            pipe: { imgDownload in
                XCTAssertEqual(UIImagePNGRepresentation(imgDownload.image), stubbedData)
            }) { () -> Promise<WMFImageDownload> in
                self.imageController.fetchImageWithURL(testURL)
            }
    }


    func testReceivingErrorResponseRejects() {
        let testURL = NSURL(string: "https://upload.wikimedia.org/foo")!
        let stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)

        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString).andFailWithError(stubbedError)

        expectPromise(toReport() as ImageDownloadPromiseErrorCallback,
            pipe: { error in
                let error = error as NSError
                XCTAssertEqual(error.code, stubbedError.code)
                XCTAssertEqual(error.domain, stubbedError.domain)
                // ErrorType <-> NSError conversions lose userInfo? https://forums.developer.apple.com/thread/4809
                // let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as! NSURL
                // XCTAssertEqual(failingURL, testURL)
            }) { () -> Promise<WMFImageDownload> in
                self.imageController.fetchImageWithURL(testURL)
            }
    }

    // MARK: - Cancellation

    func testCancelingDownloadCatchesWithCancellationError() {
        let testURL = NSURL(string:"https://foo")!
        let observationToken =
            NSNotificationCenter.defaultCenter().addObserverForName(SDWebImageDownloadStartNotification, object: nil, queue: nil) { _ -> Void in
            self.imageController.cancelFetchForURL(testURL)
        }
        NSURLProtocol.registerClass(WMFHTTPHangingProtocol)
        defer {
            NSURLProtocol.unregisterClass(WMFHTTPHangingProtocol)
            NSNotificationCenter.defaultCenter().removeObserver(observationToken)
        }
        expectPromise(toReport(ErrorPolicy.AllErrors) as ImageDownloadPromiseErrorCallback,
        pipe: { (err: ErrorType) -> Void in
            XCTAssert((err as! CancellableErrorType).cancelled, "Expected promise error to be cancelled but was \(err)")
        },
        timeout: 2) { () -> Promise<WMFImageDownload> in
            return self.imageController.fetchImageWithURL(testURL)
        }
    }

    func testCancellationDoesNotAffectRetry() {
        let testURL = NSURL(string:"https://foo@\(UInt(UIScreen.mainScreen().scale))x.png")!
        let testImage = UIImage(named: "image-placeholder")!
        let stubbedData = UIImagePNGRepresentation(testImage)!

        [0...100].forEach { _ in
            NSURLProtocol.registerClass(WMFHTTPHangingProtocol)

            let firstRequest: Promise<WMFImageDownload> = imageController.fetchImageWithURL(testURL)

            expect(self.imageController.imageManager.imageDownloader.isDownloadingImageAtURL(testURL))
            .toEventually(beTrue(), timeout: 2)

            imageController.cancelFetchForURL(testURL)

            NSURLProtocol.unregisterClass(WMFHTTPHangingProtocol)
            LSNocilla.sharedInstance().start()
            defer {
                LSNocilla.sharedInstance().stop()
            }

            stubRequest("GET", testURL.absoluteString).andReturnRawResponse(stubbedData)

            let secondRequest: Promise<WMFImageDownload> = imageController.fetchImageWithURL(testURL)

            expect(secondRequest.value.flatMap({ UIImagePNGRepresentation($0.image) }))
            .toEventually(equal(stubbedData), timeout: 10)
            expect((firstRequest.error as? CancellableErrorType)?.cancelled).toEventually(beTrue(), timeout: 5)
        }
    }

    func testSDWebImageDownloaderOperationThreadSafety() {
        NSURLProtocol.registerClass(WMFHTTPHangingProtocol)
        defer {
            NSURLProtocol.unregisterClass(WMFHTTPHangingProtocol)
        }

        [0...1000].forEach { _ in
            let downloadOperation = SDWebImageDownloaderOperation(
                request: NSURLRequest(URL: NSURL(string: "https://test.org/foo")!),
                options: [],
                progress: nil,
                completed: nil,
                cancelled: nil
            )

            let testThread = NSThread(target: downloadOperation, selector: Selector("start"), object: nil)
            testThread.start()

            expect(downloadOperation.executing).toEventually(beTrue())
            expect(downloadOperation.finished).toEventually(beFalse())
            expect(downloadOperation.valueForKey("thread") as? NSThread).toEventually(beIdenticalTo(testThread))

            /*
             A previous modification to SDWebImage which intended to simplify cancel<->retry race conditions introduced
             a deadlock.  This test verifies that cancelling the operation at the same time that the connection finishes
             loading doesn't cause a deadlock.
             
             See https://github.com/wikimedia/SDWebImage/commit/5c85e9042226df2ab8fc5f7c3d5370dc4f2a035f
            */
            let operations: [() -> Void] = [
                downloadOperation.cancel, {
                downloadOperation.performSelector(
                    Selector("connectionDidFinishLoading:"),
                    onThread: testThread,
                    withObject: nil,
                    waitUntilDone: false)
            }]

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                dispatch_apply(2, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                    operations[$0]()
                }
            }

            expect(downloadOperation.executing)
            .toEventually(
                beFalse(),
                timeout: 5,
                description: "Operations should support simultaneous cancellation & completion w/o deadlocking.")
        }
    }

    func testDeallocCancelsUnresovledFetches() {
        if NSProcessInfo.processInfo()
                        .isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9,
                                                                                  minorVersion: 0,
                                                                                  patchVersion: 0)) {
            // HAX: this functionality works when verified manually, but it appears that dealloc'ing the image controller
            // can't happen while main thread is blocked (waiting for expectations) in iOS 8.
            return
        }
        NSURLProtocol.registerClass(WMFHTTPHangingProtocol)
        defer {
            NSURLProtocol.unregisterClass(WMFHTTPHangingProtocol)
        }
        let testURL = NSURL(string:"https://foo.org/bar.jpg")!
        expectPromise(toReport(ErrorPolicy.AllErrors) as ImageDownloadPromiseErrorCallback,
            pipe: { (err: ErrorType) -> Void in
                XCTAssert((err as! CancellableErrorType).cancelled, "Expected promise error to be cancelled but was \(err)")
            },
            timeout: 5) { () -> Promise<WMFImageDownload> in
                let promise: Promise<WMFImageDownload> =
                self.imageController.fetchImageWithURL(testURL)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 4)), dispatch_get_global_queue(0, 0)) {
                    self.imageController = nil
                }
                return promise
        }
    }

    func testCancelCacheRequestCatchesWithCancellationError() throws {
        // copy some test fixture image to a temp location
        let testFixtureDataPath = NSURL(string: wmf_bundle().resourcePath!)!.URLByAppendingPathComponent("golden-gate.jpg")
        let tempPath = NSURL(string:WMFRandomTemporaryFileOfType("jpg"))!
        try! NSFileManager.defaultManager().copyItemAtURL(testFixtureDataPath, toURL: tempPath)
        defer {
            // remove temporarily copied test data
            try! NSFileManager.defaultManager().removeItemAtURL(tempPath)
        }
        let testURL = NSURL(string: "//foo/bar")!

        expectPromise(toReport(ErrorPolicy.AllErrors) as ImageDownloadPromiseErrorCallback,
        pipe: { (err: ErrorType) -> Void in
            XCTAssert((err as! CancellableErrorType).cancelled, "Expected promise error to be cancelled but was \(err)")
        },
        timeout: 2) { () -> Promise<WMFImageDownload> in
            self.imageController
                // import temp fixture data into image controller's disk cache
                .importImage(fromFile: tempPath.absoluteString, withURL: testURL)
                // then, attempt to retrieve it from the cache
                .then() {
                  let promise = self.imageController.cachedImageWithURL(testURL)
                  // but, cancel before the data is retrieved
                  self.imageController.cancelFetchForURL(testURL)
                  return promise
                }
        }
    }

    // MARK: - Import

    func testImportImageMovesFileToCorrespondingPathInDiskCache() {
        let testFixtureDataPath =
            NSURL(fileURLWithPath: wmf_bundle().resourcePath!).URLByAppendingPathComponent("golden-gate.jpg")

        let tempImageCopyURL = NSURL(fileURLWithPath: WMFRandomTemporaryFileOfType("jpg"))

        try! NSFileManager.defaultManager().copyItemAtURL(testFixtureDataPath, toURL: tempImageCopyURL)

        let testURL = NSURL(string: "//foo/bar")!

        expectPromise(toResolve(), timeout: 2) {
            self.imageController.importImage(fromFile: tempImageCopyURL.path!, withURL: testURL)
        }

        XCTAssertFalse(self.imageController.hasDataInMemoryForImageWithURL(testURL),
                       "Importing image to disk should bypass the memory cache")

        XCTAssertTrue(self.imageController.hasDataOnDiskForImageWithURL(testURL))

        XCTAssertEqual(self.imageController.diskDataForImageWithURL(testURL),
                       NSFileManager.defaultManager().contentsAtPath(testFixtureDataPath.path!))
    }
}
