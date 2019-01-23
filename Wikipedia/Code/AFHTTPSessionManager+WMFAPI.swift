public typealias SessionManagerSuccess = ((URLSessionDataTask, Any?) -> Swift.Void)?
public typealias SessionManagerFailure = ((URLSessionDataTask?, Error) -> Swift.Void)?

extension AFHTTPSessionManager {
    @objc (wmf_apiPOSTWithParameters:success:failure:)
    @discardableResult public func wmf_apiPOST(with parameters: Any?, success: SessionManagerSuccess, failure: SessionManagerFailure = nil) -> URLSessionDataTask? {
        return post(WMFAPIPath, parameters: parameters, progress: nil, success: success, failure: failure)
    }
}
