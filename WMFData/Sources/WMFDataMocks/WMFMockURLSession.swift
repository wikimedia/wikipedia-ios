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
    
    actor Actor {
        var url: URL?
        
        func getURL() -> URL? {
            return self.url
        }
        
        func setURL(_ url: URL?) {
            self.url = url
        }
    }
    
    let actor: Actor = Actor()
    
    nonisolated func getURLSyncBridge() -> URL? {
        var result: URL? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.actor.getURL()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {
        
        Task {
            await actor.setURL(request.url)
        }

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

final class WMFMockServerErrorSession: WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WMFMockURLSessionDataTask()
    }

    func clearCachedData() {
        // no-op
    }
}

final class WMFMockNoInternetConnectionSession: WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        completionHandler(nil, nil, error)
        return WMFMockURLSessionDataTask()
    }

    func clearCachedData() {
        // no-op
    }
}

final class WMFMockMissingDataSession: WMFURLSession {
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFData.WMFURLSessionDataTask {

        let response = HTTPURLResponse(url: URL(string: "http://wikipedia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        completionHandler(nil, response, nil)
        return WMFMockURLSessionDataTask()
    }

    func clearCachedData() {
        // no-op
    }
}
