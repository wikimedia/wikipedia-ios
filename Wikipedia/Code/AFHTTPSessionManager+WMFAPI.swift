
extension AFHTTPSessionManager {
    public func wmf_apiPOSTWithParameters(_ parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        return self.post(WMFAPIPath, parameters: parameters, progress: nil, success:success, failure:failure)
    }
}
