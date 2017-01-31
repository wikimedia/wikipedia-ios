
import Foundation

enum WMFPasswordResetterError: LocalizedError {
    case cannotExtractResetStatus
    case resetStatusNotSuccess
    var errorDescription: String? {
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

class WMFPasswordResetter {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    func isFetching() -> Bool {
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
        
        if let userName = userName {
            parameters["user"] = userName
        }else {
            if let email = email {
                parameters["email"] = email
            }
        }
        
        manager.post("/w/api.php", parameters: parameters, progress: nil, success: {
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
