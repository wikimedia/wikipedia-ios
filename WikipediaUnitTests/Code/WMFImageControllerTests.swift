import UIKit
import XCTest
import Nocilla

class WMFImageControllerTests: XCTestCase {
    var imageController: ImageController!
    
    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
        imageController = ImageController.temporaryController()
        imageController.deleteTemporaryCache()
    }
    
    override func tearDown() {
        LSNocilla.sharedInstance().stop()
        // might have been set to nil in one of the tests. delcared as implicitly unwrapped for convenience
        imageController?.deleteTemporaryCache()
        super.tearDown()
    }
    
    // MARK: - Simple fetching
    
    func testReceivingDataResponseResolves() {
        let testURL = URL(string: "https://upload.wikimedia.org/foo@\(Int(UIScreen.main.scale))x.png")!
        let testImage = UIImage(imageLiteralResourceName: "splashscreen-wordmark")
        let stubbedData = testImage.pngData()

        _ = stubRequest("GET", testURL.absoluteString as LSMatcheable?).andReturnRawResponse(stubbedData)
        
        let expectation = self.expectation(description: "wait for image download")
        
        let failure = { (error: Error) in
            XCTFail()
            expectation.fulfill()
        }
        
        let success = { (imgDownload: ImageDownload) in
            XCTAssertNotNil(imgDownload.image);
            expectation.fulfill()
        }
        
        self.imageController.fetchImage(withURL: testURL, failure:failure, success: success)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }
    
    
    func testReceivingErrorResponseRejects() {
        let testURL = URL(string: "https://upload.wikimedia.org/foo")!
        let stubbedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        
        stubRequest("GET", testURL.absoluteString as LSMatcheable?).andFailWithError(stubbedError)
        
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
        
        let success = { (imgDownload: ImageDownload) in
            XCTFail()
            expectation.fulfill()
        }
        
        self.imageController.fetchImage(withURL:testURL, failure:failure, success: success)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }
    
    func testCancellationDoesNotAffectRetry() {
        let testImage = UIImage(imageLiteralResourceName: "splashscreen-wordmark")
        let stubbedData = testImage.pngData()!
        let scale = Int(UIScreen.main.scale)
        let testURLString = "https://example.com/foo@\(scale)x.png"
        guard let testURL = URL(string:testURLString) else {
            return
        }
        
        
        URLProtocol.registerClass(WMFHTTPHangingProtocol.self)
        
        
        let failure = { (error: Error) in
        }
        
        let success = { (imgDownload: ImageDownload) in
        }
        
        let token = imageController.fetchImage(withURL: testURL, priority: URLSessionTask.defaultPriority, failure:failure, success: success)
        
        imageController.cancelFetch(withURL: testURL, token: token)

        URLProtocol.unregisterClass(WMFHTTPHangingProtocol.self)
        
        _ = stubRequest("GET", testURLString as LSMatcheable?).andReturnRawResponse(stubbedData)
        
        let secondExpectation = self.expectation(description: "wait for image download");
        
        let secondFailure = { (error: Error) in
            XCTFail()
            secondExpectation.fulfill()
        }
        
        let secondsuccess = { (imgDownload: ImageDownload) in
            XCTAssertNotNil(imgDownload.image);
            secondExpectation.fulfill()
        }
        
        imageController.fetchImage(withURL: testURL, failure:secondFailure, success: secondsuccess)
        
        waitForExpectations(timeout: WMFDefaultExpectationTimeout) { (error) in
        }
    }
}
