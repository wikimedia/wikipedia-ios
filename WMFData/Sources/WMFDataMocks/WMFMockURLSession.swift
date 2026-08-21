import Foundation
import WMFData

final class WMFMockURLSessionDataTask: WMFURLSessionDataTask {
    func resume() {
        
    }
}

struct WMFMockData: Codable {
    let oneInt: Int
    let twoString: String
}

// @unchecked Sendable: test-only; the recorded url var is written and read serially by tests.
final class WMFMockSuccessURLSession: WMFURLSession, @unchecked Sendable {
    
    var url: URL?
    
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {
        self.url = request.url
        
        let encoder = JSONEncoder()

        let data = try? encoder.encode(WMFMockData(oneInt: 1, twoString: "two"))
        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(data, response, nil)
        return WMFMockURLSessionDataTask()
    }
    
    func clearCachedData() {
        // no-op
    }
}

final class WMFMockServerErrorSession: WMFURLSession, @unchecked Sendable {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WMFMockURLSessionDataTask()
    }
    
    func clearCachedData() {
        // no-op
    }
}

final class WMFMockNoInternetConnectionSession: WMFURLSession, @unchecked Sendable {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completionHandler(nil, nil, error)
        return WMFMockURLSessionDataTask()
    }
    
    func clearCachedData() {
        // no-op
    }
}

final class WMFMockMissingDataSession: WMFURLSession, @unchecked Sendable {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WMFMockURLSessionDataTask()
    }
    
    func clearCachedData() {
        // no-op
    }
}
