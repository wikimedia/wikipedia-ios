
extension AFHTTPSessionManager {
    func wmf_apiPOSTWithParameters(parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        return self.post(WMFAPIPath, parameters: parameters, progress: nil, success:success, failure:failure)
    }
}
