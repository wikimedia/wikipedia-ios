//
//  WMFImageControllerCancellationTests.swift
//  Wikipedia
//
//  Created by Brian Gerstle on 8/11/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

import UIKit
import XCTest
import Wikipedia

class WMFImageControllerTests: XCTestCase {
    var imageController: WMFImageController!

    override func setUp() {
        super.setUp()
        imageController = WMFImageController.temporaryController()
    }

    override func tearDown() {
        super.tearDown()
        imageController.deleteAllImages()
        LSNocilla.sharedInstance().stop()
    }

    func testReceivingDataResponseResolves() {
        let testURL = NSURL(string: "https://upload.wikimedia.org/foo")!
        let stubbedData = UIImagePNGRepresentation(UIImage(named: "lead-default"))

        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString).andReturnRawResponse(stubbedData)

        expectPromise(toResolve(),
            pipe: { imgDownload in
                XCTAssertEqual(UIImagePNGRepresentation(imgDownload.image), stubbedData)
            }) { () -> Promise<ImageDownload> in
                self.imageController.fetchImageWithURL(testURL)
            }
    }


    func testReceivingErrorResponseRejects() {
        let testURL = NSURL(string: "https://upload.wikimedia.org/foo")!
        let stubbedError = NSError(domain: "test", code: 0, userInfo: nil)

        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString).andFailWithError(stubbedError)

        expectPromise(toCatch(),
            pipe: { error in
                XCTAssertEqual(error.code, stubbedError.code)
                XCTAssertEqual(error.domain, stubbedError.domain)
                let failingURL = error.userInfo![NSURLErrorFailingURLErrorKey] as! NSURL
                XCTAssertEqual(failingURL, testURL)
            }) { () -> Promise<ImageDownload> in
                self.imageController.fetchImageWithURL(testURL)
            }
    }

    func testCancelUnresolvedRequestCatchesWithCancellationError() {
        /*
         try to download an image from our repo on GH (as opposed to some external URL which might change)
         at least if this changes, we can easily point to another image in the repo
         */
        let testURL = NSURL(string:"https://github.com/wikimedia/wikipedia-ios/blob/master/WikipediaUnitTests/Fixtures/golden-gate.jpg?raw=true")!
        expectPromise(toCatch(policy: CatchPolicy.AllErrors),
        pipe: { err in
            XCTAssert(err.cancelled, "Expected promise error to be cancelled but was \(err)")
        }) { () -> Promise<ImageDownload> in
            let promise = self.imageController.fetchImageWithURL(testURL)
            self.imageController.cancelFetchForURL(testURL)
            return promise
        }
    }

    func testCancelCacheRequestCatchesWithCancellationError() {
        // copy some test fixture image to a temp location
        let testFixtureDataPath =
            self.wmf_bundle().resourcePath!.stringByAppendingPathComponent("golden-gate.jpg")

        let tempPath = WMFRandomTemporaryFileOfType("jpg")

        NSFileManager.defaultManager().copyItemAtPath(testFixtureDataPath,
                                                      toPath: tempPath,
                                                      error: nil)

        let testURL = NSURL(string: "//foo/bar")!

        expectPromise(toCatch(policy: CatchPolicy.AllErrors),
        pipe: { err in
            XCTAssert(err.cancelled, "Expected promise error to be cancelled but was \(err)")
        }) { () -> Promise<ImageDownload> in
            self.imageController
                // import temp fixture data into image controller's disk cache
                .importImage(fromFile: tempPath, withURL: testURL)
                // then, attempt to retrieve it from the cache
                .then() {
                  let promise = self.imageController.cachedImageWithURL(testURL)
                  // but, cancel before the data is retrieved
                  self.imageController.cancelFetchForURL(testURL)
                  return promise
                }
        }

        // remove temporarily copied test data
        NSFileManager.defaultManager().removeItemAtPath(tempPath, error: nil)
    }
}
