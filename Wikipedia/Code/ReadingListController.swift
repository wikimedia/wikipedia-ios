import Foundation

@objc(WMFReadingListController)
class ReadingListController: NSObject {
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let session = Session.shared
    fileprivate let tokenFetcher = WMFAuthTokenFetcher()
    fileprivate let basePath = "/api/rest_v1/data/lists/"

    @objc init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }


    fileprivate func post(path: String, completion: @escaping (Error?) -> Void) {
        guard
            let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL(),
            let host = siteURL.host
        else {
            return
        }

        let fullPath = basePath.appending(path)
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: host, method: .post, path: fullPath, queryParameters: ["csrf_token": token.token]) { (result , response, error) in
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

