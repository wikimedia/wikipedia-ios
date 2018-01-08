import Foundation

struct APIReadingLists: Codable {
    let lists: [APIReadingList]
    let next: String?
}

struct APIReadingList: Codable {
    let id: Int
    let name: String
    let description: String
    let created: String
    let updated: String
}

class ReadingListsAPIController: NSObject {
    fileprivate let session = Session.shared
    fileprivate lazy var tokenFetcher: WMFAuthTokenFetcher = {
        return WMFAuthTokenFetcher()
    }()
    fileprivate let basePath = "/api/rest_v1/data/lists/"
    fileprivate let host = "en.wikipedia.org"
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
    
    fileprivate func get<T>(path: String, completionHandler: @escaping (T?, URLResponse?, Error?) -> Swift.Void) where T : Codable  {
        let fullPath = basePath.appending(path)
        session.jsonCodableTask(host: host, method: .get, path: fullPath, completionHandler: completionHandler)?.resume()
    }
    
    
    @objc func setupReadingLists() {
        post(path: "setup") { (error) in
            
        }
    }
    
    @objc func teardownReadingLists() {
        post(path: "teardown") { (error) in
            
        }
    }
    
    func getAllReadingLists(completion: @escaping (APIReadingLists?, Error?) -> Swift.Void ) {
        get(path: "") { (lists: APIReadingLists?, response, error) in
            print("\(lists) \(response) \(error)")
        }
    }
}
