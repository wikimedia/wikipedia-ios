
public enum WMFPasswordResetterError: LocalizedError {
    case cannotExtractResetStatus
    case resetStatusNotSuccess
    case accountError(String)

    public var errorDescription: String? {
        switch self {
        case .cannotExtractResetStatus:
            return "Could not extract status"
        case .resetStatusNotSuccess:
            return "Password reset did not succeed"
        case .accountError(let message):
            return message
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
    public func resetPassword(siteURL: URL, userName:String?, email:String?, success: @escaping WMFPasswordResetterResultBlock, failure: @escaping WMFErrorHandler){
        var parameters = [
            "action": "resetpassword",
            "format": "json"
        ];
        
        if let userName = userName, !userName.isEmpty {
            parameters["user"] = userName
        }else {
            if let email = email, !email.isEmpty {
                parameters["email"] = email
            }
        }
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            if let error = result?["error"] as? [String: Any], let info = error["info"] as? String {
                failure(WMFPasswordResetterError.accountError(info))
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
