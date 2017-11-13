import Foundation

@objc(WMFReadingListController)
class ReadingListController: NSObject {
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let session = Session.shared
    fileprivate let tokenFetcher = WMFAuthTokenFetcher()

    @objc init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }



    @objc func setup() {
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage!.siteURL()

        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { (token) in
            self.session.jsonDictionaryTask(host: "readinglists.wmflabs.org", method: .post, path: "/api/rest_v1/data/lists/setup", queryParameters: ["csrf_token": token.token]) { (result , response, error) in
                print("result:\(String(describing: result))")
                }?.resume()
        }) { (failure) in

        }



        //            self.getJSONDictionaryFor(host: "readinglists.wmflabs.org", method: "POST", path: "/api/rest_v1/data/lists/", queryParameters: ["csrf_token": token], bodyParameters: ["name": "Planets", "description": "Planets of the Solar System"]) { (result, response, error) in
        //                print("result:\(String(describing: result))")
        //                }?.resume()


    }

}

