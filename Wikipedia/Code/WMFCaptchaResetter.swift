
public enum WMFCaptchaResetterError: LocalizedError {
    case cannotExtractCaptchaIndex
    case zeroLengthIndex
    public var errorDescription: String? {
        switch self {
        case .cannotExtractCaptchaIndex:
            return "Could not extract captcha index"
        case .zeroLengthIndex:
            return "Valid captcha reset index not obtained"
        }
    }
}

public typealias WMFCaptchaResetterResultBlock = (WMFCaptchaResetterResult) -> Void

public struct WMFCaptchaResetterResult {
    var index: String
    init(index:String) {
        self.index = index
    }
}

public class WMFCaptchaResetter {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager.operationQueue.operationCount > 0
    }
    
    public func resetCaptcha(siteURL: URL, success: @escaping WMFCaptchaResetterResultBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        let parameters = [
            "action": "fancycaptchareload",
            "format": "json"
        ];
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: { (_, response) in
            guard
                let response = response as? [String : AnyObject],
                let fancycaptchareload = response["fancycaptchareload"] as? [String: Any],
                let index = fancycaptchareload["index"] as? String
                else {
                    failure(WMFCaptchaResetterError.cannotExtractCaptchaIndex)
                    return
            }
            guard index.characters.count > 0 else {
                failure(WMFCaptchaResetterError.zeroLengthIndex)
                return
            }
            success(WMFCaptchaResetterResult.init(index: index))
        }, failure: { (_, error) in
            failure(error)
        })
    }
}
