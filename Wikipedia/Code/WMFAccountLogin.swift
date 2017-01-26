
import Foundation

enum WMFLoginAccountError: LocalizedError {
    case statusNotPass(String?)
    var errorDescription: String? {
        switch self {
        case .statusNotPass(let message?):
            return "Unable to login: \(message)"
        default:
            return "Unable to login: Status not PASS"
        }
    }
}

class WMFLoginResult: MTLModel, MTLJSONSerializing {
    var status: String?
    var username: String?
    var message: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return [
            "status": "status",
            "username": "username",
            "message": "message"
        ]
    }

    private func validatePassStatus(_ status: String?, message: String?) throws {
        guard let status = status, status == "PASS" else {
            throw WMFLoginAccountError.statusNotPass(message)
        }
    }

    override func validate() throws {
        try validatePassStatus(status, message: message)
    }
}

class WMFAccountLogin {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    func login(
        username: String,
        password: String,
        token: String,
        siteURL: URL,
        completion: WMFURLSessionDataTaskSuccessHandler,
        failure: WMFURLSessionDataTaskFailureHandler)
    {
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFLoginResult.self, fromKeypath: "clientlogin")
        
        let params = [
            "action": "clientlogin",
            "username": username,
            "password": password,
            "loginreturnurl": "https://www.wikipedia.org",
            "logintoken": token,
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: completion, failure: failure)
    }
}
