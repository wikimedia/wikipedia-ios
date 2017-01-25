
import Foundation

enum WMFApiResponse {
    case token(String)
    case errorInfo
    case warnings
    case resetPasswordStatus
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func wmf_apiResponse(_ response: WMFApiResponse) -> String?{
        switch response {
        case .token(let token):
            guard
                let query = self["query"] as? [String: Any],
                let tokens = query["tokens"] as? [String: Any],
                let token = tokens[token] as? String
                else {
                    return nil
            }
            return token
        case .errorInfo:
            guard
                let errorDict = self["error"] as? [String: Any],
                let info = errorDict["info"] as? String
                else {
                    return nil
            }
            return info
        case .warnings:
            guard
                let warningsDict = self["warnings"] as? [String: Any],
                let main = warningsDict["main"] as? [String: Any],
                let warnings = main["*"] as? String
                else {
                    return nil
            }
            return warnings
        case .resetPasswordStatus:
            guard
                let resetpasswordDict = self["resetpassword"] as? [String: Any],
                let status = resetpasswordDict["status"] as? String
                else {
                    return nil
            }
            return status
        }
    }
}



