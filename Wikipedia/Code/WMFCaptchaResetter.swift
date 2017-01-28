
import Foundation

class WMFCaptchaResetter {
    private let manager = AFHTTPSessionManager.wmf_createDefault()
    
    public func isResetting() -> Bool {
        return manager!.operationQueue.operationCount > 0
    }
    
    public func resetCaptcha(siteURL: URL, completion: WMFURLSessionDataTaskSuccessHandler, failure: WMFURLSessionDataTaskFailureHandler){
        
        let manager = AFHTTPSessionManager(baseURL: siteURL)
        manager.responseSerializer = WMFMantleJSONResponseSerializer.init(forInstancesOf: WMFCaptchaResetterResult.self, fromKeypath: "fancycaptchareload")
        
        let parameters = [
            "action": "fancycaptchareload",
            "format": "json"
        ];
        
        manager.post("/w/api.php", parameters: parameters, progress: nil, success: completion, failure: failure)
    }
    
    static public func newCaptchaImageURLFromOldURL(_ oldURL: String, newID: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: "wpCaptchaId=([^&]*)", options: .caseInsensitive)
            return regex.stringByReplacingMatches(in: oldURL, options: [], range: NSMakeRange(0, oldURL.characters.count), withTemplate: "wpCaptchaId=\(newID)")
        } catch {
            return nil
        }
    }
}
