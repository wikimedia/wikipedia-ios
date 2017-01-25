import Foundation

enum WMFApiToken: String {
    case csrf, login, createaccount
    func responseKey () -> String {
        return self.rawValue + "token"
    }
}

class WMFTokenFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func fetchToken(token: WMFApiToken, siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFTokenResponseSerializer.init(token: token)
        let params = [
            "action": "query",
            "meta": "tokens",
            "type": token.rawValue,
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: completion, failure: failure)
    }
}

private class WMFTokenResponseSerializer: AFJSONResponseSerializer {
    private let token: WMFApiToken
    init(token: WMFApiToken){
        self.token = token
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        
        guard let responseDict = super.responseObject(for: response, data: data, error: error) as? [String: AnyObject] else {
            if error?.pointee == nil {
                error?.pointee = WMFAPIResponseError.noResponseDictionary as NSError
            }
            return nil
        }

        guard let token = responseDict.wmf_apiResponse(.token(token.responseKey())) else {
            guard let errorInfo = responseDict.wmf_apiResponse(.errorInfo) else {
                error?.pointee = WMFAPIResponseError.dictionaryWithoutErrorInfo as NSError
                return nil
            }
            error?.pointee = WMFAPIResponseError.dictionaryWithErrorInfo(errorInfo) as NSError
            return nil
        }
        
        return token
    }
}
