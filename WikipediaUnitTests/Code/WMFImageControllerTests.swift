import UIKit
import XCTest
@testable import Wikipedia
import Nimble
import Nocilla

class WMFImageControllerTests: XCTestCase {
    var imageController: WMFImageController!

    override func setUp() {
        super.setUp()
        imageController = WMFImageController.temporary()
        imageController.deleteAllImages()
    }

    override func tearDown() {
        super.tearDown()
        // might have been set to nil in one of the tests. delcared as implicitly unwrapped for convenience
        imageController?.deleteAllImages()
        LSNocilla.sharedInstance().stop()
    }

    // MARK: - Simple fetching
    
    func testReceivingDataResponseResolves() {
        let testURL = URL(string: "https://upload.wikimedia.org/foo@\(Int(UIScreen.main.scale))x.png")!
        let testImage = UIImage(named: "image-placeholder")!
        let stubbedData = UIImagePNGRepresentation(testImage)

        LSNocilla.sharedInstance().start()
        _ = stubRequest("GET", testURL.absoluteString as LSMatcheable!).andReturnRawResponse(stubbedData)
        
        let expectation = self.expectation(description: "wait for image download")
        
        let failure = { (error: Error) in
            XCTFail()
            expectation.fulfill()
        }
        
        let success = { (imgDownload: WMFImageDownload) in
            XCTAssertNotNil(imgDownload.image);
            expectation.fulfill()
        }
        
        self.imageController.fetchImageWithURL(testURL, failure:failure, success: success)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }


    func testReceivingErrorResponseRejects() {
        let testURL = URL(string: "https://upload.wikimedia.org/foo")!
        let stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)

        LSNocilla.sharedInstance().start()
        stubRequest("GET", testURL.absoluteString as LSMatcheable!).andFailWithError(stubbedError)
        
        let expectation = self.expectation(description: "wait for image download");
        
        let failure = { (error: Error) in
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
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }

    func testCancellationDoesNotAffectRetry() {
        let testImage = UIImage(named: "image-placeholder")!
        let stubbedData = UIImagePNGRepresentation(testImage)!
        let scale = Int(UIScreen.main.scale)
        let testURLString = "https://example.com/foo@\(scale)x.png"
        guard let testURL = URL(string:testURLString) else {
            return
        }
        
        imageController.deleteImageWithURL(testURL)
        
        URLProtocol.registerClass(WMFHTTPHangingProtocol.self)
        

        let failure = { (error: Error) in
        }
        
        let success = { (imgDownload: WMFImageDownload) in
        }
        
        let observationToken =
            NotificationCenter.default.addObserver(forName: NSNotification.Name.SDWebImageDownloadStart, object: nil, queue: nil) { _ -> Void in
                self.imageController.cancelFetchForURL(testURL)
        }
        
        imageController.fetchImageWithURL(testURL, failure:failure, success: success)
        
        NotificationCenter.default.removeObserver(observationToken)
        
        URLProtocol.unregisterClass(WMFHTTPHangingProtocol.self)
        LSNocilla.sharedInstance().start()
        defer {
            LSNocilla.sharedInstance().stop()
        }
        
        _ = stubRequest("GET", testURLString as LSMatcheable!).andReturnRawResponse(stubbedData)
        
        let secondExpectation = self.expectation(description: "wait for image download");
        
        let secondFailure = { (error: Error) in
            XCTFail()
            secondExpectation.fulfill()
        }
        
        let secondsuccess = { (imgDownload: WMFImageDownload) in
            XCTAssertNotNil(imgDownload.image);
            secondExpectation.fulfill()
        }
        
        imageController.fetchImageWithURL(testURL, failure:secondFailure, success: secondsuccess)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
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
//        waitForExpectationsWithTimeout(WMFDefaultExpectationTimeout) { (error) in
//        }
//    }
//
//    // MARK: - Import
//
    func testImportImageMovesFileToCorrespondingPathInDiskCache() {
        let testFixtureDataPath =
            URL(fileURLWithPath: wmf_bundle().resourcePath!).appendingPathComponent("golden-gate.jpg")

        let tempImageCopyURL = URL(fileURLWithPath: WMFRandomTemporaryFileOfType("jpg"))

        try! FileManager.default.copyItem(at: testFixtureDataPath, to: tempImageCopyURL)

        let testURL = URL(string: "//foo/bar")!
        
        let expectation = self.expectation(description: "wait");
        
        let failure = { (error: Error) in
            XCTFail()
            expectation.fulfill()
        }
        
        let success = {
            expectation.fulfill()
        }
        
        self.imageController.importImage(fromFile: tempImageCopyURL.path, withURL: testURL, failure: failure, success: success)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }


        XCTAssertFalse(self.imageController.hasDataInMemoryForImageWithURL(testURL),
                       "Importing image to disk should bypass the memory cache")

        let secondExpect = self.expectation(description: "wait");

        
        self.imageController.hasDataOnDiskForImageWithURL(testURL) { (hasData) in
             XCTAssertTrue(hasData)
            secondExpect.fulfill()
        }
       
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
        
        XCTAssertEqual(self.imageController.diskDataForImageWithURL(testURL),
                       FileManager.default.contents(atPath: testFixtureDataPath.path))
    }
}
