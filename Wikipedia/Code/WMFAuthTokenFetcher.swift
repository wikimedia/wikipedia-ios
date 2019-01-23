
@objc public enum WMFAuthTokenType: Int {
    case csrf, login, createAccount
}

public enum WMFAuthTokenError: LocalizedError {
    case cannotExtractToken
    case zeroLengthToken
    public var errorDescription: String? {
        switch self {
        case .cannotExtractToken:
            return "Could not extract token"
        case .zeroLengthToken:
            return "Invalid zero-length token fetched"
        }
    }
}

public typealias WMFAuthTokenBlock = (WMFAuthToken) -> Void

public class WMFAuthToken: NSObject {
    @objc public var token: String
    @objc public var type: WMFAuthTokenType
    public var isAuthorized: Bool
    @objc init(token:String, type:WMFAuthTokenType) {
        self.token = token
        self.type = type
        self.isAuthorized = token != "+\\"
    }
}

public class WMFAuthTokenFetcher: Fetcher {
    @objc public func fetchToken(ofType type: WMFAuthTokenType, siteURL: URL, success: @escaping WMFAuthTokenBlock, failure: @escaping WMFErrorHandler){
        func stringForToken(_ type: WMFAuthTokenType) -> String {
            switch type {
            case .csrf:
                return "csrf"
            case .login:
                return "login"
            case .createAccount:
                return "createaccount"
            }
        }

        let parameters = [
            "action": "query",
            "meta": "tokens",
            "type": stringForToken(type),
            "format": "json"
        ]
        
        performMediaWikiAPIPOST(for: siteURL, with: parameters) { (result, response, error) in
            if let error = error {
                failure(error)
                return
            }
            guard
                let query = result?["query"] as? [String: Any],
                let tokens = query["tokens"] as? [String: Any],
                let token = tokens[stringForToken(type) + "token"] as? String
                else {
                    failure(WMFAuthTokenError.cannotExtractToken)
                    return
            }
            guard token.count > 0 else {
                failure(WMFAuthTokenError.zeroLengthToken)
                return
            }
            success(WMFAuthToken(token: token, type: type))
        }
    }
}
