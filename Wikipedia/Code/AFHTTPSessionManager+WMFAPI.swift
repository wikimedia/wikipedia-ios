public typealias SessionManagerSuccess = ((URLSessionDataTask, Any?) -> Swift.Void)?
public typealias SessionManagerFailure = ((URLSessionDataTask?, Error) -> Swift.Void)?

extension AFHTTPSessionManager {
    @objc (wmf_apiPOSTWithParameters:success:failure:)
    @discardableResult public func wmf_apiPOST(with parameters: Any?, success: SessionManagerSuccess, failure: SessionManagerFailure = nil) -> URLSessionDataTask? {
        return post(WMFAPIPath, parameters: parameters, progress: nil, success: success, failure: failure)
    }
    @objc (wmf_apiZeroSafePOSTWithURL:parameters:success:failure:)
    @discardableResult public func wmf_apiZeroSafePOST(with url: URL, parameters: Any?, success: SessionManagerSuccess, failure: SessionManagerFailure = nil) -> URLSessionDataTask? {
        guard let zeroRatedAPIURL = url.wmf_zeroRatedAPIURL() else {
            assertionFailure("Expected URL not found")
            return nil
        }
        return post(zeroRatedAPIURL.absoluteString, parameters: parameters, progress: nil, success: success, failure: failure)
    }
    @objc (wmf_apiZeroSafeGETWithURL:parameters:success:failure:)
    @discardableResult public func wmf_apiZeroSafeGET(with url: URL, parameters: Any?, success: SessionManagerSuccess, failure: SessionManagerFailure = nil) -> URLSessionDataTask? {
        guard let zeroRatedAPIURL = url.wmf_zeroRatedAPIURL() else {
            assertionFailure("Expected URL not found")
            return nil
        }
        return get(zeroRatedAPIURL.absoluteString, parameters: parameters, progress: nil, success: success, failure: failure)
    }
}

private extension URL {
    func wmf_zeroRatedAPIURL() -> URL? {
        // If Zero rated use mobile domain, else use desktop domain.
        return SessionSingleton.sharedInstance().zeroConfigurationManager.isZeroRated ? NSURL.wmf_mobileAPIURL(for: self) : NSURL.wmf_desktopAPIURL(for: self)
    }
}
