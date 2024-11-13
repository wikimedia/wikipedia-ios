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

final class WMFMockSuccessURLSession: WMFURLSession {
    
    var url: URL?
    
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {
        self.url = request.url
        
        let encoder = JSONEncoder()

        let data = try? encoder.encode(WMFMockData(oneInt: 1, twoString: "two"))
        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(data, response, nil)
        return WMFMockURLSessionDataTask()
    }
}

final class WMFMockServerErrorSession: WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WMFMockURLSessionDataTask()
    }
}

final class WMFMockNoInternetConnectionSession: WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completionHandler(nil, nil, error)
        return WMFMockURLSessionDataTask()
    }
}

final class WMFMockMissingDataSession: WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WMFMockURLSessionDataTask()
    }
}
