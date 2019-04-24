
import Foundation

public enum TalkPageError: Error {
    case invalidFetchCompletion
}

public class TalkPageController {
    let fetcher: TalkPageFetcher
    weak var dataStore: MWKDataStore?
    
    @objc required init(fetcher: TalkPageFetcher, dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.fetcher = fetcher
    }
    
    public func updateOrCreateTalkPage(for name: String, host: String, completion: ((TalkPage?, Error?) -> Void)? = nil) {
        guard let moc = dataStore?.viewContext else {
            completion?(nil, RequestError.invalidParameters)
            return
        }
        //todo: better host
        fetcher.fetchTalkPage(for: name, host: host) { (talkPage, error) in
            
            guard let talkPage = talkPage else {
                let error = error ?? TalkPageError.invalidFetchCompletion
                completion?(nil, error)
                return
            }
            
            moc.perform {
                do {
                    let talkPage = try moc.wmf_createOrUpdateTalkPage(talkPage: talkPage)
                    completion?(talkPage, nil)
                } catch let error {
                    DDLogError("Error fetching talk page: \(error.localizedDescription)")
                    completion?(nil, error)
                }
            }
        }
    }
}
