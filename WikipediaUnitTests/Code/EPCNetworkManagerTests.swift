
import XCTest
@testable import WMF

fileprivate class MockStorageManager: EPCStorageManager {
    
    var createAndSavePostCalled = false
    var deleteStalePostsCalled = false
    var updatePostsCalled = false
    var expectedCompletedPosts: [EPCPost] = []
    var expectedFailedPosts: [EPCPost] = []
    var completedPosts: [EPCPost] = []
    var failedPosts: [EPCPost] = []
    
    override func setPersisted(_ key: String, _ value: NSCoding) {
        
    }
    
    override func deletePersisted(_ key: String) {
        
    }
    
    override func getPersisted(_ key: String) -> NSCoding? {
        return nil
    }
    
    override func createAndSavePost(with url: URL, body: NSDictionary) {
        createAndSavePostCalled = true
    }
    
    override func updatePosts(completedIDs: Set<NSManagedObjectID>, failedIDs: Set<NSManagedObjectID>) {
        
        let moc = self.managedObjectContextToTest
        moc.performAndWait {
            for moid in completedIDs {
                let mo = try? moc.existingObject(with: moid)
                guard let post = mo as? EPCPost else {
                    continue
                }
                
                completedPosts.append(post)
            }
            
            for moid in failedIDs {
                let mo = try? moc.existingObject(with: moid)
                guard let post = mo as? EPCPost else {
                    continue
                }
                
                failedPosts.append(post)
            }
        }
        
        updatePostsCalled = true
    }
    
    override func deleteStalePosts() {
        deleteStalePostsCalled = true
    }
    
    override func fetchPostsForPosting() -> [EPCPost] {
        
        let moc = self.managedObjectContextToTest
        var posts: [EPCPost] = []
        moc.performAndWait {
            
            for i in 0..<6 {
                if let post = NSEntityDescription.insertNewObject(forEntityName: "EPCPost", into: moc) as? EPCPost {
                    post.body = ["index": i] as NSDictionary
                    post.recorded = Date()
                    post.userAgent = WikipediaAppUtils.versionedUserAgent()
                    post.url = URL(string: "https://en.wikipedia.org/\(i)")
                    posts.append(post)
                    if i % 2 == 0 {
                        expectedCompletedPosts.append(post)
                    } else {
                        expectedFailedPosts.append(post)
                    }
                    
                    do {
                        try moc.save()
                    } catch {
                        XCTFail("Failure saving initial post batch")
                    }
                }
            }
        }
        
        return posts
    }
}

fileprivate class MockSession: Session {
    
    private let dict =  ["key": "value"]
    var attempt = 0
    
    enum Mode {
        case error
        case success
        case switchPerAttempt
    }
    
    var mode: Mode = .error
    var useNetworkError = false
    
    public override func dataTask(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], cachePolicy: URLRequest.CachePolicy? = nil, priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {
        sharedDataTaskOverride(completionHandler: completionHandler)
    }
    
    public override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        sharedDataTaskOverride(completionHandler: completionHandler)
    }
    
    private func sharedDataTaskOverride(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask? {

        var mode: MockSession.Mode = self.mode
        
        if case .switchPerAttempt = self.mode {
            mode = attempt % 2 == 0 ? .success : .error
        }
        
        attempt = attempt + 1
        
        switch mode {
        case .error:
            let response = HTTPURLResponse(url: URL(string: "https://en.wikipedia.org")!, statusCode: 500, httpVersion: nil, headerFields: [:])
            let error = useNetworkError ? NSError(domain: NSURLErrorDomain, code: 1, userInfo: nil) : NSError(domain: "wikipedia.org", code: 1, userInfo: nil)
            completionHandler(nil, response, error)
        case .success:
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                let response = HTTPURLResponse(url: URL(string: "https://en.wikipedia.org")!, statusCode: 200,  httpVersion: nil, headerFields: [:])
                completionHandler(jsonData, response, nil)
            } catch {
                XCTFail("MockSession - failure returning mocked success call")
            }
        default:
            break
        }
        
        return nil
    }
}

class EPCNetworkManagerTests: XCTestCase {
    
    private let storageManager: MockStorageManager = {
        guard let tempPath = WMFRandomTemporaryPath() else {
            XCTFail("Failure generating temp path.")
            fatalError()
        }
        let randomURL = NSURL.fileURL(withPath: tempPath)
        
        guard let storageManager = MockStorageManager(permanentStorageURL: randomURL, legacyEventLoggingService: LegacyService.shared, postBatchSize: 5) else {
            XCTFail("Failure initializing temporaryStorageManager.")
            fatalError()
        }
        
        return storageManager
    }()
    
    private let session = MockSession(configuration: Configuration.current)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFailureAttempts5TimesThenStopsWithNilData() throws {
        
        let networkManager = EPCNetworkManager(storageManager: storageManager, session: session)
        session.mode = .error

        let expectation = self.expectation(description: "Downloading")
        
        networkManager.httpDownload(url: URL(string: "https://en.wikipedia.org")!) { (data) in
            
            XCTAssertNil(data)
            
            expectation.fulfill()
        }
        
         waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(session.attempt, 5)
    }
    
    func testSuccessAttempts1TimeThenStopsWithData() throws {
        
        let networkManager = EPCNetworkManager(storageManager: storageManager, session: session)
        session.mode = .success

        let expectation = self.expectation(description: "Downloading")
        
        networkManager.httpDownload(url: URL(string: "https://en.wikipedia.org")!) { (data) in
            
            XCTAssertNotNil(data)
            
            expectation.fulfill()
        }
        
         waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertEqual(session.attempt, 1)
    }
    
    func testHttpPostCallsStorageManager() {
        let networkManager = EPCNetworkManager(storageManager: storageManager, session: session)
        networkManager.httpPost(url: URL(string: "https://en.wikipedia.org")!, body: [:] as NSDictionary)
        XCTAssert(storageManager.createAndSavePostCalled, "Expected networkManager's httpPost to pass on through to storageManager's createAndSavePostItemCalled.")
    }
    
    func testHTTPTryPostMakesADeleteStaleCall() {
        let networkManager = EPCNetworkManager(storageManager: storageManager, session: session)
        
        let expectation = self.expectation(description: "Posting batch of items")
        
        networkManager.httpTryPost {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssert(storageManager.deleteStalePostsCalled, "Expected httpTryPost to call storageManager's deleteStalePostItems")
    }
    
    func testHttpTryPostFunnelsToStorageManagerUpdatePostItems() {
        let networkManager = EPCNetworkManager(storageManager: storageManager, session: session)
        session.mode = .switchPerAttempt
        
        let expectation = self.expectation(description: "Posting batch of items")
        
        networkManager.httpTryPost {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(storageManager.updatePostsCalled, "Expected httpTryPost to call storageManager's updatePostItemsCalled")
        
        let sortedBlock: ((EPCPost, EPCPost) -> Bool) = { lhs, rhs in
            guard let leftBody = lhs.body as? [String: AnyObject],
                let leftIndex = leftBody["index"] as? Int,
                let rightBody = rhs.body as? [String: AnyObject],
                let rightIndex = rightBody["index"] as? Int else {
                return false
            }
            
            return leftIndex < rightIndex
        }
        
        let sortedExpectedCompletedPosts = storageManager.expectedCompletedPosts.sorted(by: sortedBlock)
        let sortedCompletedPosts = storageManager.completedPosts.sorted(by: sortedBlock)
        let sortedExpectedFailedPosts = storageManager.expectedFailedPosts.sorted(by: sortedBlock)
        let sortedFailedPosts = storageManager.failedPosts.sorted(by: sortedBlock)
        
        XCTAssertEqual(sortedExpectedCompletedPosts, sortedCompletedPosts)
        XCTAssertEqual(sortedExpectedFailedPosts, sortedFailedPosts)
    }
    
    func testHttpTryPostWithNetworkErrorDoesNotFunnelFailuresToStorageManager() {
        let networkManager = EPCNetworkManager(storageManager: storageManager, session: session)
        session.mode = .switchPerAttempt
        session.useNetworkError = true
        
        let expectation = self.expectation(description: "Posting batch of items")
        
        networkManager.httpTryPost {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(storageManager.updatePostsCalled, "Expected httpTryPost to call storageManager's updatePostItemsCalled")
        
        let sortedBlock: ((EPCPost, EPCPost) -> Bool) = { lhs, rhs in
            guard let leftBody = lhs.body as? [String: AnyObject],
                let leftIndex = leftBody["index"] as? Int,
                let rightBody = rhs.body as? [String: AnyObject],
                let rightIndex = rightBody["index"] as? Int else {
                return false
            }
            
            return leftIndex < rightIndex
        }
        
        let sortedExpectedCompletedPosts = storageManager.expectedCompletedPosts.sorted(by: sortedBlock)
        let sortedCompletedPosts = storageManager.completedPosts.sorted(by: sortedBlock)
        
        XCTAssertEqual(sortedExpectedCompletedPosts, sortedCompletedPosts)
        XCTAssertEqual(storageManager.failedPosts.count, 0)
    }

}
