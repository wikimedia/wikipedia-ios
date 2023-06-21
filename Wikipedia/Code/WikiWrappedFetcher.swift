import Foundation
import WMF

class WikiWrappedFetcher: Fetcher {
    
    func fetchWikiWrapped(completion: @escaping (Result<WikiWrappedAPIResponse, Error>) -> Void) {
        
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate != NULL && key BEGINSWITH 'https://en.wikipedia.org'")
        articleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false), NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)]
        
        let dataStore = MWKDataStore.shared()
        let titles: [String]
        
        do {
            let result = try dataStore.viewContext.fetch(articleRequest)
            titles = result.compactMap {$0.displayTitle?.normalizedPageTitle}
        } catch {
            print("Failed")
            completion(.failure(RequestError.unexpectedResponse))
            return
        }
        
        let siteURL = Configuration.current.defaultSiteURL
        
        /*
         https://en.wikipedia.org/w/api.php?action=query&format=json&prop=cirrusdoc&titles=Barack_Obama&formatversion=2
         */
        
        let params = ["action": "query",
                      "format": "json",
                      "prop": "cirrusdoc",
                      "titles": titles.joined(separator: "|"),
                      "formatversion": "2"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { result, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let query = result?["query"] as? [String: Any],
                  let pages = query["pages"] as? [[String: Any]] else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            var articles: [WikiWrappedAPIResponse.WikiWrappedArticle] = []
            for page in pages {
                guard let title = page["title"] as? String,
                      let cirrusDoc = page["cirrusdoc"] as? [[String: Any]],
                      let source = cirrusDoc.first?["source"] as? [String: Any],
                      let topicStrings = source["ores_articletopics"] as? [String] else {
                    continue
                }
                
                var topics: [WikiWrappedAPIResponse.WikiWrappedArticle.Topic] = []
                for topicString in topicStrings {
                    if topicString.hasPrefix("drafttopic/") || topicString.hasPrefix("articletopic/") {
                        continue
                    }
                    
                    let splitTopicStrings = topicString.components(separatedBy: "|")
                    guard splitTopicStrings.count == 2, let finalTopicString = splitTopicStrings.first,
                          let finalWeight = Int(splitTopicStrings[1]) else {
                        continue
                    }
                    
                    topics.append(WikiWrappedAPIResponse.WikiWrappedArticle.Topic(name: finalTopicString, weight: finalWeight))
                }
                
                let article = WikiWrappedAPIResponse.WikiWrappedArticle.init(title: title, topics: topics)
                articles.append(article)
            }
            
            completion(.success(WikiWrappedAPIResponse.init(articles: articles)))
        }
    }
}
