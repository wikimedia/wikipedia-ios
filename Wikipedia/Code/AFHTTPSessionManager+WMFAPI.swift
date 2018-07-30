
extension AFHTTPSessionManager {
    @objc public func wmf_apiPOSTWithParameters(_ parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        return self.wmf_apiPOSTWithURLString(WMFAPIPath, parameters: parameters, success: success)
    }
    @objc public func wmf_apiPOSTWithURLString(_ URLString: String, parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        return self.post(URLString, parameters: parameters, progress: nil, success:success, failure:failure)
    }
}
