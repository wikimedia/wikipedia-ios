import Foundation

class ReadingListsAPIController: NSObject {
    fileprivate let session = Session.shared
    fileprivate lazy var tokenFetcher: WMFAuthTokenFetcher = {
        return WMFAuthTokenFetcher()
    }()
    fileprivate let basePath = "/api/rest_v1/data/lists/"
    fileprivate let host = "readinglists.wmflabs.org"
    fileprivate let scheme = "https"
    
    fileprivate func post(path: String, completion: @escaping (Error?) -> Void) {
        var components = URLComponents()
        components.host = host
        components.scheme = scheme
        guard
            let siteURL = components.url
            else {
                return
        }
        
        let fullPath = basePath.appending(path)
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: self.host, method: .post, path: fullPath, queryParameters: ["csrf_token": token.token]) { (result , response, error) in
                completion(error)
                }?.resume()
        }) { (failure) in
            completion(failure)
        }
    }
    
    fileprivate func get(path: String, completion: (Error?)) {
        guard
            let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL(),
            let host = siteURL.host
            else {
                return
        }
        
        let fullPath = basePath.appending(path)
        session.jsonDictionaryTask(host: host, method: .post, path: fullPath) { (result , response, error) in
            }?.resume()
    }
    
    
    @objc func setup() {
        post(path: "setup") { (error) in
            
        }
    }
    
    @objc func teardown() {
        post(path: "teardown") { (error) in
            
        }
    }
}
