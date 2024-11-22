import WMFComponents

public enum WMFAccountCreatorError: LocalizedError {
    case cannotExtractStatus
    case statusNotPass(String?)
    case blockedError(String)
    case wrongCaptcha
    case usernameUnavailable
    public var errorDescription: String? {
        switch self {
        case .cannotExtractStatus:
            return "Could not extract status"
        case .statusNotPass(let message?):
            return message.removingHTML
        case .blockedError(let message):
            return message
        case .wrongCaptcha:
            return WMFLocalizedString("field-alert-captcha-invalid", value:"Invalid CAPTCHA", comment:"Alert shown if CAPTCHA is not correct")
        case .usernameUnavailable:
            return WMFLocalizedString("field-alert-username-unavailable", value:"Username not available", comment:"Alert shown if new username is not available")
        default:
            return "Unable to create account: Reason unknown"
        }
    }
}

public typealias WMFAccountCreatorResultBlock = (WMFAccountCreatorResult) -> Void

public struct WMFAccountCreatorResult {
    var status: String
    var username: String
    var message: String?
}

public class WMFAccountCreator: Fetcher {
    
    struct CheckUsernameAPIResponse: Codable {
        struct Query: Codable {
            struct User: Codable {
                struct CanCreateError: Codable {
                    let message: String
                    let params: [String]
                    let type: String
                    let code: String
                }
                
                enum CodingKeys: String, CodingKey {
                    case userId = "userid"
                    case name
                    case missing
                    case canCreate = "cancreate"
                    case canCreateError = "cancreateerror"
                }
                
                let userId: Int?
                let name: String
                let missing: Bool?
                let canCreate: Bool?
                let canCreateError: [CanCreateError]?
            }
            
            let users: [User]
        }
        
        enum CodingKeys: String, CodingKey {
            case batchComplete = "batchcomplete"
            case query
        }
        
        let batchComplete: Bool
        let query: Query
    }
    
    public func checkUsername(
        _ username: String,
        siteURL: URL,
        success: @escaping (Bool) -> Void,
        failure: @escaping WMFErrorHandler
    ) {
        let parameters: [String: String] = [
            "action": "query",
            "list": "users",
            "ususers": username,
            "usprop": "cancreate",
            "formatversion": "2",
            "format": "json"
        ]
        
        performDecodableMediaWikiAPIGET(
            for: siteURL,
            with: parameters
        ) { (result: Result<CheckUsernameAPIResponse, Error>) in
            switch result {
            case .failure(let error):
                failure(error)
            case .success(let apiResponse):
                let usernameAvailable = apiResponse.query.users.first?.canCreate ?? false
                success(usernameAvailable)
            }
        }
    }
    
    public func createAccount(username: String, password: String, retypePassword: String, email: String?, captchaID: String?, captchaWord: String?, siteURL: URL, success: @escaping WMFAccountCreatorResultBlock, failure: @escaping WMFErrorHandler) {
        var parameters: [String: String] = [
            "action": "createaccount",
            "username": username,
            "password": password,
            "retype": retypePassword,
            "createreturnurl": "https://www.wikipedia.org",
            "createmessageformat": "html",
            "format": "json"
        ]
        if let email = email {
            parameters["email"] = email
        }
        if let captchaID = captchaID {
            parameters["captchaId"] = captchaID
        }
        if let captchaWord = captchaWord {
            parameters["captchaWord"] = captchaWord
        }
        
        performTokenizedMediaWikiAPIPOST(tokenType: .createAccount, to: siteURL, with: parameters) { (result, response, error) in

            if let error = error {
                failure(error)
                return
            }
            guard
                let createaccount = result?["createaccount"] as? [String : AnyObject],
                let status = createaccount["status"] as? String
                else {
                    failure(WMFAccountCreatorError.cannotExtractStatus)
                    return
            }
            let message = createaccount["message"] as? String ?? ""
            guard status == "PASS" else {
                if let messageCode = createaccount["messagecode"] as? String {
                    switch messageCode {
                    case "captcha-createaccount-fail":
                        failure(WMFAccountCreatorError.wrongCaptcha)
                        return
                    case "userexists":
                        failure(WMFAccountCreatorError.usernameUnavailable)
                        return
                    default: break
                    }
                    
                    if messageCode.contains("block") {
                        failure(WMFAccountCreatorError.blockedError(message))
                        return
                    }
                }
                failure(WMFAccountCreatorError.statusNotPass(message))
                return
            }
            let normalizedUsername = createaccount["username"] as? String ?? username
            success(WMFAccountCreatorResult.init(status: status, username: normalizedUsername, message: message))
        }
    }
}
