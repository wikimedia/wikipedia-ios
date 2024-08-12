import Foundation
import WMFData

#if DEBUG

fileprivate extension WMFData.WMFServiceRequest {
    var isWatchlistGetListNoFilter: Bool {
        guard let action = parameters?["action"] as? String,
              let list = parameters?["list"] as? String,
              let wlshow = parameters?["wlshow"] as? String else {
            return false
        }
        
        return method == .GET && action == "query"
            && list == "watchlist" && wlshow == ""
    }
    
    var isWatchlistGetListBotOnly: Bool {
        guard let action = parameters?["action"] as? String,
              let list = parameters?["list"] as? String,
              let wlshow = parameters?["wlshow"] as? String else {
            return false
        }
        
        return method == .GET && action == "query"
            && list == "watchlist" && wlshow == "bot"
    }
    
    var isWatchlistPostWatchArticleExpiryNever: Bool {
         guard let action = parameters?["action"] as? String,
               let expiry = parameters?["expiry"] as? String else {
             return false
         }

         return method == .POST && action == "watch" && expiry == "never"
     }

     var isWatchlistPostWatchArticleExpiryDate: Bool {
         guard let action = parameters?["action"] as? String,
               let expiry = parameters?["expiry"] as? String else {
             return false
         }

         return method == .POST && action == "watch" && (expiry == "1 week" ||
                                                         expiry == "1 month" ||
                                                         expiry == "3 months" ||
                                                         expiry == "6 months")
     }

     var isWatchlistPostUnwatchArticle: Bool {
         guard let action = parameters?["action"] as? String,
               let unwatch = parameters?["unwatch"] as? String else {
             return false
         }

         return method == .POST && action == "watch" && unwatch == "1"
     }
    
    var isWatchlistGetWatchStatus: Bool {
        guard let action = parameters?["action"] as? String,
              let prop = parameters?["prop"] as? String,
              let inprop = parameters?["inprop"] as? String else {
            return false
        }

        return method == .GET && action == "query" &&
        prop == "info" &&
        inprop == "watched" &&
        parameters?["meta"] == nil &&
        parameters?["uiprop"] == nil
    }

    var isWatchlistGetWatchStatusWithRollbackRights: Bool {
        guard let action = parameters?["action"] as? String,
              let prop = parameters?["prop"] as? String,
              let inprop = parameters?["inprop"] as? String,
              let meta = parameters?["meta"] as? String,
              let uiprop = parameters?["uiprop"] as? String else {
            return false
        }

        return method == .GET && action == "query" &&
        prop == "info" &&
        inprop == "watched" &&
        meta == "userinfo" &&
        uiprop == "rights"
    }
    
    var isWatchlistPostRollback: Bool {
        guard let action = parameters?["action"] as? String else {
            return false
        }

        return method == .POST && action == "rollback"
    }
    
    var isWatchlistGetUndoSummaryPrefix: Bool {

        guard let action = parameters?["action"] as? String,
              let meta = parameters?["meta"] as? String,
              let ammessages = parameters?["ammessages"] as? String else {
            return false
        }

        return method == .GET && action == "query" && meta == "allmessages" && ammessages == "undo-summary"
    }
    
    var isWatchlistPostUndo: Bool {
        guard let action = parameters?["action"] as? String,
              let title = parameters?["title"] as? String,
              let summary = parameters?["summary"] as? String,
              let undo = parameters?["undo"] as? String else {
            return false
        }

        return method == .POST && action == "edit" && !title.isEmpty && !summary.isEmpty && !undo.isEmpty
    }
}

public class WMFMockWatchlistMediaWikiService: WMFService {

    public var randomizeGetWatchStatusResponse: Bool = false // used in WMFComponents Demo app
    
    public init() {
        
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        completion(.success(jsonData))
    }
    
    public func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            completion(.failure(WMFMockError.unableToDeserialize))
            return
        }
        
        completion(.success(jsonDict))
    }
    
    public func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        
        guard let jsonData = jsonData(for: request) else {
            completion(.failure(WMFMockError.unableToPullData))
            return
        }
        
        let decoder = JSONDecoder()
        
        guard let response = try? decoder.decode(T.self, from: jsonData) else {
            completion(.failure(WMFMockError.unableToDeserialize))
            return
        }
        
        completion(.success(response))
    }
    
    public func performDecodablePOST<R, T>(request: R, completion: @escaping (Result<T, Error>) -> Void) where R : WMFData.WMFServiceRequest, T : Decodable {
        
    }
    
    private func jsonData(for request: WMFData.WMFServiceRequest) -> Data? {
        if request.isWatchlistGetListNoFilter {
            guard let host = request.url?.host,
                  let index = host.firstIndex(of: "."),
                  let subdomain = request.url?.host?.prefix(upTo: index) else {
                return nil
            }
            
            let resourceName: String
            if subdomain == "commons" {
                resourceName = "watchlist-get-list-commons"
            } else if (request.url?.host ?? "").contains("wikidata") {
                resourceName = "watchlist-get-list-wikidata"
            } else {
                resourceName = "watchlist-get-list-\(subdomain)"
            }
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isWatchlistGetListBotOnly {
            guard let host = request.url?.host,
                  let index = host.firstIndex(of: "."),
                  let subdomain = request.url?.host?.prefix(upTo: index) else {
                return nil
            }
            
            let resourceName: String
            if subdomain == "commons" {
                resourceName = "watchlist-get-list-commons-bot-only"
            } else if (request.url?.host ?? "").contains("wikidata") {
                resourceName = "watchlist-get-list-wikidata-bot-only"
            } else {
                resourceName = "watchlist-get-list-\(subdomain)-bot-only"
            }
            
            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }
            
            return jsonData
        } else if request.isWatchlistPostWatchArticleExpiryNever {
            guard let url = Bundle.module.url(forResource: "watchlist-post-watch-article-expiry-never", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistPostWatchArticleExpiryDate {
            guard let url = Bundle.module.url(forResource: "watchlist-post-watch-article-expiry-date", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistPostUnwatchArticle {
            guard let url = Bundle.module.url(forResource: "watchlist-post-unwatch-article", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistGetWatchStatusWithRollbackRights {
            
            let resourceName: String
            if randomizeGetWatchStatusResponse {
                let needsWatched = Int.random(in: 1...2) == 1
                resourceName = needsWatched ? "watchlist-get-watch-status-and-rollback-rights-watched" : "watchlist-get-watch-status-and-rollback-rights-unwatched"
            } else {
                resourceName = "watchlist-get-watch-status-and-rollback-rights-unwatched"
            }

            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData

        } else if request.isWatchlistGetWatchStatus {

            let resourceName: String
            if randomizeGetWatchStatusResponse {
                let needsWatched = Int.random(in: 1...2) == 1
                resourceName = needsWatched ? "watchlist-get-watch-status-watched" : "watchlist-get-watch-status-unwatched"
            } else {
                resourceName = "watchlist-get-watch-status-watched"
            }

            guard let url = Bundle.module.url(forResource: resourceName, withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistPostRollback {
            guard let url = Bundle.module.url(forResource: "watchlist-post-rollback-article", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistGetUndoSummaryPrefix {
            guard let url = Bundle.module.url(forResource: "watchlist-get-undo-summary-prefix", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        } else if request.isWatchlistPostUndo {
            guard let url = Bundle.module.url(forResource: "watchlist-post-undo-article", withExtension: "json"),
                  let jsonData = try? Data(contentsOf: url) else {
                return nil
            }

            return jsonData
        }
        
        return nil
    }
}

#endif
