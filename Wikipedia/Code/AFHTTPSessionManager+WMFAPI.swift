extension AFHTTPSessionManager {
    @objc @discardableResult public func wmf_apiPOSTWithParameters(_ parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        return self.post(WMFAPIPath, parameters: parameters, progress: nil, success:success, failure:failure)
    }
    @objc @discardableResult public func wmf_apiZeroSafePOSTWithURL(_ url: URL, parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        guard let zeroRatedAPIURL = url.wmf_zeroRatedAPIURL() else {
            assertionFailure("Expected URL not found")
            return nil
        }
        return self.post(zeroRatedAPIURL.absoluteString, parameters: parameters, progress: nil, success:success, failure:failure)
    }
    @objc @discardableResult public func wmf_zeroSafeGETWithURL(_ url: URL, parameters: Any?, success: ((URLSessionDataTask, Any?) -> Swift.Void)?, failure: ((URLSessionDataTask?, Error) -> Swift.Void)? = nil) -> URLSessionDataTask? {
        guard let zeroRatedAPIURL = url.wmf_zeroRatedAPIURL() else {
            assertionFailure("Expected URL not found")
            return nil
        }
        return self.get(zeroRatedAPIURL.absoluteString, parameters: parameters, progress: nil, success:success, failure:failure)
    }
}

private extension URL {
    func wmf_zeroRatedAPIURL() -> URL? {
        // If Zero rated use mobile domain, else use desktop domain.
        return SessionSingleton.sharedInstance().zeroConfigurationManager.isZeroRated ? NSURL.wmf_mobileAPIURL(for: self) : NSURL.wmf_desktopAPIURL(for: self)
    }
}
