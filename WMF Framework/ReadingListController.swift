import Foundation

@objc(WMFReadingListController)
class ReadingListController: NSObject {
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let session = Session.shared

    
    @objc init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    

    
    @objc func setup() {
       
            
            self.session.jsonDictionaryTask(host: "readinglists.wmflabs.org", method: .post, path: "/api/rest_v1/data/lists/setup") { (result, response, error) in
                print("result:\(String(describing: result))")
                }?.resume()

//            self.getJSONDictionaryFor(host: "readinglists.wmflabs.org", method: "POST", path: "/api/rest_v1/data/lists/", queryParameters: ["csrf_token": token], bodyParameters: ["name": "Planets", "description": "Planets of the Solar System"]) { (result, response, error) in
//                print("result:\(String(describing: result))")
//                }?.resume()


    }
    
}
