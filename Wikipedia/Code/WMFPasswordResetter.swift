
public enum WMFPasswordResetterError: LocalizedError {
    case cannotExtractResetStatus
    case resetStatusNotSuccess
    public var errorDescription: String? {
        switch self {
        case .cannotExtractResetStatus:
            return "Could not extract status"
        case .resetStatusNotSuccess:
            return "Password reset did not succeed"
        }
    }
}

public typealias WMFPasswordResetterResultBlock = (WMFPasswordResetterResult) -> Void

public struct WMFPasswordResetterResult {
    var status: String
    init(status:String) {
        self.status = status
    }
}

public class WMFPasswordResetter: Fetcher {
    public func resetPassword(siteURL: URL, token: String, userName:String?, email:String?, success: @escaping WMFPasswordResetterResultBlock, failure: @escaping WMFErrorHandler){
        var parameters = [
            "action": "resetpassword",
            "token": token,
            "format": "json"
        ];
        
        if let userName = userName, userName.count > 0 {
            parameters["user"] = userName
        }else {
            if let email = email, email.count > 0 {
                parameters["email"] = email
            }
        }
        
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let resetpassword = result?["resetpassword"] as? [String: Any],
                let status = resetpassword["status"] as? String
                else {
                    failure(WMFPasswordResetterError.cannotExtractResetStatus)
                    return
            }
            guard status == "success" else {
                failure(WMFPasswordResetterError.resetStatusNotSuccess)
                return
            }
            success(WMFPasswordResetterResult.init(status: status))
        }
    }
}
