import Foundation

/// The server's request for an hCaptcha token before it accepts an edit.
///
/// `action=edit` and `discussiontoolsedit` put the captcha in the `edit` result. Wikibase modules
/// such as `wbsetdescription` put it in the `data` of an API error instead.
public struct WMFHCaptchaRequirement: Sendable, Equatable {

    /// Nil when the server sends no key. Callers then use the edit key from the feature config.
    public let siteKey: String?

    /// True when the server rejected a passive token and wants a visible challenge.
    public let forceShowCaptcha: Bool

    public init(siteKey: String?, forceShowCaptcha: Bool) {
        self.siteKey = siteKey
        self.forceShowCaptcha = forceShowCaptcha
    }

    public init?(captcha: [String: Any]) {
        guard let type = captcha["type"] as? String,
              type.lowercased() == "hcaptcha" else {
            return nil
        }

        let key = captcha["key"] as? String
        self.siteKey = (key?.isEmpty ?? true) ? nil : key
        self.forceShowCaptcha = (captcha["error"] as? String) == "forceshowcaptcha"
    }

    public init?(editResult: [String: Any]) {
        guard let captcha = editResult["captcha"] as? [String: Any] else {
            return nil
        }
        self.init(captcha: captcha)
    }

    public init?(apiErrorResponse: [String: Any]) {
        var errors = apiErrorResponse["errors"] as? [[String: Any]] ?? []
        if let error = apiErrorResponse["error"] as? [String: Any] {
            errors.append(error)
        }

        for error in errors {
            if let data = error["data"] as? [String: Any],
               let captcha = data["captcha"] as? [String: Any],
               let requirement = WMFHCaptchaRequirement(captcha: captcha) {
                self = requirement
                return
            }
        }

        return nil
    }

    public static func requestParameters(token: String, forceShowCaptcha: Bool) -> [String: String] {
        var parameters = ["captchaword": token]
        if forceShowCaptcha {
            parameters["wgConfirmEditForceShowCaptcha"] = "1"
        }
        return parameters
    }
}
