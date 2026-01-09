// Can contain classic captcha information, or a "needsHCaptcha" boolean
public final class WMFCaptcha {
    public struct ClassicInfo {
        public let captchaID: String
        public let captchaURL: URL
        
        public init(captchaID: String, captchaURL: URL) {
            self.captchaID = captchaID
            self.captchaURL = captchaURL
        }
    }
    
    public struct HCaptchaInfo {
        public let needsHCaptcha: Bool
        
        public init(needsHCaptcha: Bool) {
            self.needsHCaptcha = needsHCaptcha
        }
    }
    
    public let classicInfo: ClassicInfo?
    public let hCaptchaInfo: HCaptchaInfo?
    
    public init(classicInfo: ClassicInfo?, hCaptchaInfo: HCaptchaInfo?) {
        self.classicInfo = classicInfo
        self.hCaptchaInfo = hCaptchaInfo
    }
    static public func captcha(from requests: [[String : AnyObject]]) -> WMFCaptcha? {
        
        let hasHCaptchaRequest = requests.first(where: { dict in
            guard let stringID = dict["id"] as? String,
                stringID.lowercased().contains("captcha"),
                  let metadata = dict["metadata"] as? [String: Any],
                let type = metadata["type"] as? String,
                  type.lowercased().contains("hcaptcha") else {
                return false
            }
            
            return true
        })
        
        if hasHCaptchaRequest != nil {
            let hCaptchaInfo = HCaptchaInfo(needsHCaptcha: true)
            return WMFCaptcha(classicInfo: nil, hCaptchaInfo: hCaptchaInfo)
        }
        
        guard
            let captchaAuthenticationRequest = requests.first(where: {$0["id"]! as! String == "CaptchaAuthenticationRequest"}),
            let fields = captchaAuthenticationRequest["fields"] as? [String : AnyObject],
            let captchaId = fields["captchaId"] as? [String : AnyObject],
            let captchaInfo = fields["captchaInfo"] as? [String : AnyObject],
            let captchaIdValue = captchaId["value"] as? String,
            let captchaInfoValue = captchaInfo["value"] as? String,
            let captchaURL = URL(string: captchaInfoValue)
            else {
                return nil
        }
        let classicInfo = WMFCaptcha.ClassicInfo(captchaID: captchaIdValue, captchaURL: captchaURL)
        return WMFCaptcha(classicInfo: classicInfo, hCaptchaInfo: nil)
    }
}
