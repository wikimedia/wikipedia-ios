public class WMFCaptcha: NSObject {
    @objc public let captchaID: String
    @objc public let captchaURL: URL
    @objc public init(captchaID:String, captchaURL:URL) {
        self.captchaID = captchaID
        self.captchaURL = captchaURL
    }
    static public func captcha(from requests: [[String : AnyObject]]) -> WMFCaptcha? {
        guard
            let captchaAuthenticationRequest = requests.first(where:{$0["id"]! as! String == "CaptchaAuthenticationRequest"}),
            let fields = captchaAuthenticationRequest["fields"] as? [String : AnyObject],
            let captchaId = fields["captchaId"] as? [String : AnyObject],
            let captchaInfo = fields["captchaInfo"] as? [String : AnyObject],
            let captchaIdValue = captchaId["value"] as? String,
            let captchaInfoValue = captchaInfo["value"] as? String,
            let captchaURL = URL(string: captchaInfoValue)
            else {
                return nil
        }
        return WMFCaptcha(captchaID: captchaIdValue, captchaURL: captchaURL)
    }
}
