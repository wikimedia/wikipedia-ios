
import Foundation

class WMFCSRFTokenFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func fetchCSRFToken(siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFCSRFTokenResponseSerializer()
        manager.post("/w/api.php", parameters: ["action": "query", "meta": "tokens", "format": "json"], progress: nil, success: completion, failure: failure)
    }
}

private class WMFCSRFTokenResponseSerializer: AFJSONResponseSerializer {
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
    
        guard let responseDict = super.responseObject(for: response, data: data, error: error) as? [String: AnyObject] else {
            if error?.pointee == nil {
                error?.pointee = WMFAPIResponseError.noResponseDictionary as NSError
            }
            return nil
        }

        guard let csrftoken = responseDict.wmf_apiResponse(.csrfToken) else {
            guard let errorInfo = responseDict.wmf_apiResponse(.errorInfo) else {
                error?.pointee = WMFAPIResponseError.dictionaryWithoutErrorInfo as NSError
                return nil
            }
            error?.pointee = WMFAPIResponseError.dictionaryWithErrorInfo(errorInfo) as NSError
            return nil
        }
        
        return csrftoken
    }
}
