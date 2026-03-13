import WMFComponents

public enum WMFAccountCreatorError: LocalizedError {
    
    public struct MediaWikiMessage {
        public let text: String
        public let code: String
        
        init?(text: String?, code: String?) {
            guard let text, let code else {
                return nil
            }
            
            self.text = text
            self.code = code
        }
    }
    
    case cannotExtractStatus
    case statusNotPass(MediaWikiMessage?)
    case blockedError(MediaWikiMessage?)
    case wrongCaptcha(MediaWikiMessage?)
    case usernameUnavailable(MediaWikiMessage?)
    case badretype(MediaWikiMessage?)
    case invalidUser(MediaWikiMessage?)
    case missingPasswords(MediaWikiMessage?)
    
    public var errorDescription: String? {
        switch self {
        case .cannotExtractStatus:
            return "Could not extract status"
        case .statusNotPass(let message):
            return message?.text.removingHTML
        case .blockedError(let message):
            return message?.text
        case .wrongCaptcha:
            return WMFLocalizedString("field-alert-captcha-invalid", value:"Invalid CAPTCHA", comment:"Alert shown if CAPTCHA is not correct")
        case .usernameUnavailable:
            return WMFLocalizedString("field-alert-username-unavailable", value:"Username not available", comment:"Alert shown if new username is not available")
        case .badretype(let message):
            return message?.text
        case .invalidUser(let message):
            return message?.text
        case .missingPasswords(let message):
            return message?.text
        }
    }
    
    public var mediaWikiMessageCode: String? {
        switch self {
        case .statusNotPass(let message),
             .blockedError(let message),
             .wrongCaptcha(let message),
             .usernameUnavailable(let message),
             .badretype(let message),
             .invalidUser(let message),
             .missingPasswords(let message):
            return message?.code
        case .cannotExtractStatus:
            return nil
        }
    }
    
    public var testKitchenValidationError: String {
        if let code = mediaWikiMessageCode {
            return "WMFAccountCreatorError.\(code)"
        } else {
            switch self {
            case .usernameUnavailable:
                return "WMFAccountCreatorError.userexists"
            case .badretype:
                return "WMFAccountCreatorError.badretype"
            case .invalidUser:
                return "WMFAccountCreatorError.invaliduser"
            case .missingPasswords:
                return "WMFAccountCreatorError.authmanager-create-no-primary"
            default:
                break
            }
        }
        return logDescription
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
    
    public func createAccount(username: String, password: String, retypePassword: String, email: String?, classicCaptchaID: String?, classicCaptchaWord: String?, hCaptchaToken: String?, siteURL: URL, success: @escaping WMFAccountCreatorResultBlock, failure: @escaping WMFErrorHandler) {
        
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
        if let captchaID = classicCaptchaID {
            parameters["captchaId"] = captchaID
        }
        
        let captchaWord = hCaptchaToken ?? classicCaptchaWord
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
            
            let messageText = createaccount["message"] as? String ?? nil
            let messageCode = createaccount["messagecode"] as? String
            let message = WMFAccountCreatorError.MediaWikiMessage(text: messageText, code: messageCode)
            
            guard status == "PASS" else {
                if let messageCode {
                    switch messageCode {
                    case "captcha-createaccount-fail":
                        failure(WMFAccountCreatorError.wrongCaptcha(message))
                        return
                    case "userexists":
                        failure(WMFAccountCreatorError.usernameUnavailable(message))
                        return
                    case "badretype":
                        failure(WMFAccountCreatorError.badretype(message))
                        return
                    case "invaliduser":
                        failure(WMFAccountCreatorError.invalidUser(message))
                        return
                    case "authmanager-create-no-primary":
                        failure(WMFAccountCreatorError.missingPasswords(message))
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
            success(WMFAccountCreatorResult.init(status: status, username: normalizedUsername, message: message?.text ?? ""))
        }
    }
}
