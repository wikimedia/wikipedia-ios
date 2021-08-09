
import Foundation

@objc(WMFEchoSubscriptionFetcher)
class EchoSubscriptionFetcher: Fetcher {
    
    @objc func subscribe(siteURL: URL?, deviceToken: NSData?, completion: @escaping (Error?) -> Void) {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let siteURL = siteURL,
              let deviceToken = deviceToken else {
            completion(RequestError.invalidParameters)
            return
        }
        
        let deviceTokenString = deviceTokenStringFromDeviceToken(deviceToken)
        let bodyParameters: [String: String] = [
            "action": "echopushsubscriptions",
            "format": "json",
            "command": "create",
            "provider": "apns",
            "providertoken": deviceTokenString,
            "topic": bundleID
        ]
    
        self.performTokenizedMediaWikiAPIPOST(to: siteURL, with: bodyParameters) { result, response, error in
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let response = response,
                  response.statusCode == 200 else {
                completion(RequestError.unexpectedResponse)
                return
            }
            
            if let responseError = RequestError.from(result?["error"] as? [String : Any]) {
                completion(responseError)
                return
            }
            
            completion(nil)
        }
    }
    
    @objc func unsubscribe(siteURL: URL?, deviceToken: NSData?, completion: ((Error?) -> Void)?) {
        
        guard let siteURL = siteURL,
              let deviceToken = deviceToken else {
            completion?(RequestError.invalidParameters)
            return
        }
        
        let deviceTokenString = deviceTokenStringFromDeviceToken(deviceToken)
        let bodyParameters: [String: String] = [
            "action": "echopushsubscriptions",
            "format": "json",
            "command": "delete",
            "providertoken": deviceTokenString
        ]
        
        self.performTokenizedMediaWikiAPIPOST(to: siteURL, with: bodyParameters) { result, response, error in
            guard error == nil else {
                completion?(error)
                return
            }
            
            guard let response = response,
                  response.statusCode == 200 else {
                completion?(RequestError.unexpectedResponse)
                return
            }
            
            if let responseError = RequestError.from(result?["error"] as? [String : Any]) {
                completion?(responseError)
                return
            }
            
            completion?(nil)
        }
    }
    
    private func deviceTokenStringFromDeviceToken(_ deviceToken: NSData) -> String {
        let tokenComponents = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let deviceTokenString = tokenComponents.joined()
        return deviceTokenString
    }
}
