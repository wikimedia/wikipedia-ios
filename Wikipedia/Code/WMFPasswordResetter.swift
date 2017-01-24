
import Foundation

class WMFPasswordResetter {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    public func isResetting() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func resetPassword(siteURL: URL, token: String, userName:String?, email:String?, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFPasswordResetterResponseSerializer()
        
        var parameters = ["action": "resetpassword", "token": token, "format": "json"];
        
        if let userName = userName {
            parameters["user"] = userName
        }else {
            if let email = email {
                parameters["email"] = email
            }
        }
        
        manager.post("/w/api.php", parameters: parameters, progress: nil, success: completion, failure: failure)
    }
}

internal class WMFPasswordResetterResponseSerializer: AFJSONResponseSerializer {
    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {
        
        guard let responseDict = super.responseObject(for: response, data: data, error: error) as? [String: AnyObject] else {
            if error?.pointee == nil {
                error?.pointee = WMFAPIResponseError.noResponseDictionary as NSError
            }
            return nil
        }

        guard let resetPasswordStatus = responseDict.wmf_apiResponse(.resetPasswordStatus) else {
            guard let errorInfo = responseDict.wmf_apiResponse(.errorInfo) else {
                error?.pointee = WMFAPIResponseError.dictionaryWithoutErrorInfo as NSError
                return nil
            }
            error?.pointee = WMFAPIResponseError.dictionaryWithErrorInfo(errorInfo) as NSError
            return nil
        }
        
        guard resetPasswordStatus == "success" else {
            error?.pointee = WMFAPIResponseError.dictionaryWithErrorInfo("Unexpected reset password status '\(resetPasswordStatus)'") as NSError
            return nil
        }
        
        return resetPasswordStatus
    }
}
