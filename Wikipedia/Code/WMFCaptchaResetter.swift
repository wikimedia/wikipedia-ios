
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

public class WMFCaptchaResetter: Fetcher {
    public func resetCaptcha(siteURL: URL, success: @escaping WMFCaptchaResetterResultBlock, failure: @escaping WMFErrorHandler){
        let parameters = [
            "action": "fancycaptchareload",
            "format": "json"
        ]
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let fancycaptchareload = result?["fancycaptchareload"] as? [String: Any],
                let index = fancycaptchareload["index"] as? String
                else {
                    failure(WMFCaptchaResetterError.cannotExtractCaptchaIndex)
                    return
            }
            guard !index.isEmpty else {
                failure(WMFCaptchaResetterError.zeroLengthIndex)
                return
            }
            success(WMFCaptchaResetterResult.init(index: index))
        }
    }
}
