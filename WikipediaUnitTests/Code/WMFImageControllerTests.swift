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
        
        let expectation = expectationWithDescription("wait for image download")
        
        let failure = { (error: ErrorType) in
            XCTFail()
        }
        
        let success = { (imgDownload: WMFImageDownload) in
            XCTAssertEqual(UIImagePNGRepresentation(imgDownload.image), stubbedData)
            expectation.fulfill()
        }
        
        self.imageController.fetchImageWithURL(testURL, failure:failure, success: success)
        
        waitForExpectationsWithTimeout(60) { (error) in
        }
    }


    func testReceivingErrorResponseRejects() {
        let testURL = NSURL(string: "https://upload.wikimedia.org/foo")!
        let stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)

        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString).andFailWithError(stubbedError)
        
        let expectation = expectationWithDescription("wait for image download");
        
        let failure = { (error: ErrorType) in
            let error = error as NSError
            // ErrorType <-> NSError conversions lose userInfo? https://forums.developer.apple.com/thread/4809
            // let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as! NSURL
            // XCTAssertEqual(failingURL, testURL)
            XCTAssertEqual(error.code, stubbedError.code)
            XCTAssertEqual(error.domain, stubbedError.domain)
            expectation.fulfill()
        }
        
        let success = { (imgDownload: WMFImageDownload) in
            XCTFail()
            expectation.fulfill()
        }
        
        self.imageController.fetchImageWithURL(testURL, failure:failure, success: success)
        
        waitForExpectationsWithTimeout(60) { (error) in
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
        
        let expectation = expectationWithDescription("wait for image download");
        
        let failure = { (error: ErrorType) in
            let error = error as NSError
            XCTAssert(error.code == NSURLErrorCancelled)
            expectation.fulfill()
        }
        
        let success = { (imgDownload: WMFImageDownload) in
            XCTFail()
            expectation.fulfill()
        }
        
        self.imageController.fetchImageWithURL(testURL, failure:failure, success: success)
        
        waitForExpectationsWithTimeout(60) { (error) in
        }
    }

    func testCancellationDoesNotAffectRetry() {
        let testURL = NSURL(string:"https://foo@\(UInt(UIScreen.mainScreen().scale))x.png")!
        let testImage = UIImage(named: "image-placeholder")!
        let stubbedData = UIImagePNGRepresentation(testImage)!
        
        [0...100].forEach { _ in
            NSURLProtocol.registerClass(WMFHTTPHangingProtocol)
            
            let expectation = expectationWithDescription("wait for image download");
            
            let failure = { (error: ErrorType) in
                let error = error as NSError
                XCTAssert(error.code == NSURLErrorCancelled)
                expectation.fulfill()
            }
            
            let success = { (imgDownload: WMFImageDownload) in
                XCTFail()
                expectation.fulfill()
            }
            
            self.imageController.fetchImageWithURL(testURL, failure:failure, success: success)
            
            expect(self.imageController.imageManager.imageDownloader.isDownloadingImageAtURL(testURL))
            .toEventually(beTrue(), timeout: 2)

            imageController.cancelFetchForURL(testURL)
            
            waitForExpectationsWithTimeout(60) { (error) in
            }

            NSURLProtocol.unregisterClass(WMFHTTPHangingProtocol)
            LSNocilla.sharedInstance().start()
            defer {
                LSNocilla.sharedInstance().stop()
            }
            
            stubRequest("GET", testURL.absoluteString).andReturnRawResponse(stubbedData)
            
            let secondExpectation = expectationWithDescription("wait for image download");
            
            let secondFailure = { (error: ErrorType) in
                XCTFail()
                secondExpectation.fulfill()
            }
            
            let secondsuccess = { (imgDownload: WMFImageDownload) in
                XCTAssertEqual(UIImagePNGRepresentation(imgDownload.image), stubbedData)
                secondExpectation.fulfill()
            }
            
            self.imageController.fetchImageWithURL(testURL, failure:secondFailure, success: secondsuccess)
            
            waitForExpectationsWithTimeout(60) { (error) in
            }
        }
    }
    
//    This test never performed as intended, there was a bug in the test that passed the wrong path which caused the cache fetch to error out.  After fixing that bug, it turns out that SDWebImage doesn't return an error when cancelling a cache fetch. Altering the behavior to match this test might have other consequences.
//    func testCancelCacheRequestCatchesWithCancellationError() throws {
//        // copy some test fixture image to a temp location
//        let path = wmf_bundle().resourcePath!;
//        let lastPathComponent = "golden-gate.jpg";
//
//        var testFixtureDataPath = NSURL(fileURLWithPath: path)
//        testFixtureDataPath = testFixtureDataPath.URLByAppendingPathComponent(lastPathComponent)
//
//        let tempFileURL = NSURL(fileURLWithPath:WMFRandomTemporaryFileOfType("jpg"))
//        do {
//            try NSFileManager.defaultManager().copyItemAtURL(testFixtureDataPath, toURL: tempFileURL)
//        } catch {
//            XCTFail()
//        }
//        
//        let testURL = NSURL(fileURLWithPath: "/foo/bar")
//
//        let expectation = expectationWithDescription("wait");
//        
//        let failure = { (error: ErrorType) in
//            XCTFail()
//            expectation.fulfill()
//        }
//        
//        let success = {
//            let failure = { (error: ErrorType) in
//                XCTAssert(true) // HAX: this test never actually copied the data
//                expectation.fulfill()
//            }
//            
//            let success = { (imgDownload: WMFImageDownload) in
//                XCTAssert(true) // HAX: this test never actually copied the data
//                expectation.fulfill()
//            }
//            self.imageController.cachedImageWithURL(testURL, failure: failure, success: success)
//            self.imageController.cancelFetchForURL(testURL)
//        }
//        
//        self.imageController.importImage(fromFile: tempFileURL.path!, withURL: testURL, failure: failure, success: success)
//        
//        waitForExpectationsWithTimeout(60) { (error) in
//        }
//    }
//
//    // MARK: - Import
//
    func testImportImageMovesFileToCorrespondingPathInDiskCache() {
        let testFixtureDataPath =
            NSURL(fileURLWithPath: wmf_bundle().resourcePath!).URLByAppendingPathComponent("golden-gate.jpg")

        let tempImageCopyURL = NSURL(fileURLWithPath: WMFRandomTemporaryFileOfType("jpg"))

        try! NSFileManager.defaultManager().copyItemAtURL(testFixtureDataPath, toURL: tempImageCopyURL)

        let testURL = NSURL(string: "//foo/bar")!
        
        let expectation = expectationWithDescription("wait");
        
        let failure = { (error: ErrorType) in
            XCTFail()
            expectation.fulfill()
        }
        
        let success = {
            expectation.fulfill()
        }
        
        self.imageController.importImage(fromFile: tempImageCopyURL.path!, withURL: testURL, failure: failure, success: success)
        
        waitForExpectationsWithTimeout(60) { (error) in
        }


        XCTAssertFalse(self.imageController.hasDataInMemoryForImageWithURL(testURL),
                       "Importing image to disk should bypass the memory cache")

        XCTAssertTrue(self.imageController.hasDataOnDiskForImageWithURL(testURL))

        XCTAssertEqual(self.imageController.diskDataForImageWithURL(testURL),
                       NSFileManager.defaultManager().contentsAtPath(testFixtureDataPath.path!))
    }
}
