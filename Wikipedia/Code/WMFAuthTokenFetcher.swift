
import Foundation

enum WMFAuthTokenType: String {
    case csrf, login, createAccount
}

enum WMFAuthTokenError: LocalizedError {
    case cannotExtractToken
    case zeroLengthToken
    var errorDescription: String? {
        switch self {
        case .cannotExtractToken:
            return "Could not extract token"
        case .zeroLengthToken:
            return "Invalid zero-length token fetched"
        }
    }
}

public typealias WMFAuthTokenBlock = (WMFAuthToken) -> Void

public struct WMFAuthToken {
    var token: String
    var type: WMFAuthTokenType
    init(token:String, type:WMFAuthTokenType) {
        self.token = token
        self.type = type
    }
}

class WMFAuthTokenFetcher {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    func isFetching() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    public func fetchToken(ofType type: WMFAuthTokenType, siteURL: URL, completion: @escaping WMFAuthTokenBlock, failure: @escaping WMFErrorHandler){
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFApiJsonResponseSerializer.init();
        let params = [
            "action": "query",
            "meta": "tokens",
            "type": type.rawValue.lowercased(),
            "format": "json"
        ]
        manager.post("/w/api.php", parameters: params, progress: nil, success: {
            (_, response: Any?) in
            guard
                let response = response as? [String : AnyObject],
                let query = response["query"] as? [String: Any],
                let tokens = query["tokens"] as? [String: Any],
                let token = tokens[type.rawValue.lowercased() + "token"] as? String
            else {
                failure(WMFAuthTokenError.cannotExtractToken)
                return
            }
            guard token.characters.count > 0 else {
                failure(WMFAuthTokenError.zeroLengthToken)
                return
            }
            completion(WMFAuthToken.init(token: token, type: type))
        }, failure: {
            (_, error: Error) in
            failure(error)
        })
    }
}
