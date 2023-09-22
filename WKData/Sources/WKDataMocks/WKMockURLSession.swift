import Foundation
import WKData

final class WKMockURLSessionDataTask: WKURLSessionDataTask {
    func resume() {
        
    }
}

struct WKMockData: Codable {
    let oneInt: Int
    let twoString: String
}

final class WKMockSuccessURLSession: WKURLSession {
    
    var url: URL?
    
    func wkDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WKData.WKURLSessionDataTask {
        self.url = request.url
        
        let encoder = JSONEncoder()

        let data = try? encoder.encode(WKMockData(oneInt: 1, twoString: "two"))
        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(data, response, nil)
        return WKMockURLSessionDataTask()
    }
}

final class WKMockServerErrorSession: WKURLSession {
    func wkDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WKData.WKURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WKMockURLSessionDataTask()
    }
}

final class WKMockNoInternetConnectionSession: WKURLSession {
    func wkDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WKData.WKURLSessionDataTask {

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completionHandler(nil, nil, error)
        return WKMockURLSessionDataTask()
    }
}

final class WKMockMissingDataSession: WKURLSession {
    func wkDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WKData.WKURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WKMockURLSessionDataTask()
    }
}
