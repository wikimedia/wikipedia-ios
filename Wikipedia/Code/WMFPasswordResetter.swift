
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

public class WMFPasswordResetterResult: NSObject {
    var status: String
    init(status:String) {
        self.status = status
    }
}

public class WMFPasswordResetter: NSObject {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    public func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    public func resetPassword(siteURL: URL, token: String, userName:String?, email:String?, completion: @escaping WMFPasswordResetterResultBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();

        var parameters = [
            "action": "resetpassword",
            "token": token,
            "format": "json"
        ];
        
        if let userName = userName, userName.characters.count > 0 {
            parameters["user"] = userName
        }else {
            if let email = email, email.characters.count > 0 {
                parameters["email"] = email
            }
        }
        
        _ = manager.wmf_apiPOSTWithParameters(parameters, success: {
            (_, response: Any?) in
            guard
                let response = response as? [String : AnyObject],
                let resetpassword = response["resetpassword"] as? [String: Any],
                let status = resetpassword["status"] as? String
                else {
                    failure(WMFPasswordResetterError.cannotExtractResetStatus)
                    return
            }
            guard status == "success" else {
                failure(WMFPasswordResetterError.resetStatusNotSuccess)
                return
            }
            completion(WMFPasswordResetterResult.init(status: status))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
