
import XCTest
@testable import WMF

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
    
    private let session = MockSession(configuration: Configuration.current)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFailureAttempts5TimesThenStopsWithNilData() throws {
        
        let networkManager = EPCNetworkManager(session: session)
        session.mode = .error

        let expectation = self.expectation(description: "Downloading")
        
        networkManager.httpDownload(url: URL(string: "https://en.wikipedia.org")!) { (data) in
            
            XCTAssertNil(data)
            
            expectation.fulfill()
        }
        
         waitForExpectations(timeout: 15, handler: nil)
        
        XCTAssertEqual(session.attempt, 6)
    }
    
    func testSuccessAttempts1TimeThenStopsWithData() throws {
        
        let networkManager = EPCNetworkManager(session: session)
        session.mode = .success

        let expectation = self.expectation(description: "Downloading")
        
        networkManager.httpDownload(url: URL(string: "https://en.wikipedia.org")!) { (data) in
            
            XCTAssertNotNil(data)
            
            expectation.fulfill()
        }
        
         waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertEqual(session.attempt, 1)
    }

}
