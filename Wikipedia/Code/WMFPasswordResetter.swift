
import Foundation

enum WMFPasswordResetError: LocalizedError {
    case statusNotSuccess
    var errorDescription: String? {
        return "Password reset did not succeed"
    }
}

class WMFPasswordResetResult: MTLModel, MTLJSONSerializing {
    var status: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return [
            "status": "status"
        ]
    }
    
    private func validateSuccessStatus() throws {
        guard let status = status, status == "success" else {
            throw WMFPasswordResetError.statusNotSuccess
        }
    }
    
    override func validate() throws {
        try validateSuccessStatus()
    }
}

class WMFPasswordResetter {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    public func isResetting() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func resetPassword(siteURL: URL, token: String, userName:String?, email:String?, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFPasswordResetResult.self, fromKeypath: "resetpassword")
        
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
        
        manager.post("/w/api.php", parameters: parameters, progress: nil, success: completion, failure: failure)
    }
}
