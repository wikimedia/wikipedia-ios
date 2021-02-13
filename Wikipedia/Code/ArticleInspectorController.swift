import Foundation
import CocoaLumberjackSwift

@available(iOS 13.0, *)
class ArticleInspectorController {
    
    private let articleURL: URL
    private let fetcher = ArticleInspectorFetcher()
    
    init(articleURL: URL) {
        self.articleURL = articleURL
    }
    
    var isEnabled: Bool {
        
        //TODO: replace with experiment checking, site=en & !rtl logic
        return false
    }
    
    func articleContentFinishedLoading(messagingController: ArticleWebMessagingController) {
        
        guard isEnabled else {
            return
        }
        
        guard let title = articleURL.wmf_title?.denormalizedPageTitle else {
            DDLogError("Failure constructing article title.")
            return
        }
        
        let group = DispatchGroup()
        
        var articleHtml: String?
        var wikiWhoResponse: WikiWhoResponse?
        
        group.enter()
        messagingController.htmlContent { (response) in
            
            defer {
                group.leave()
            }
            
            guard let response = response else {
                return
            }
            
            articleHtml = response
        }
        
        group.enter()
        fetcher.fetchWikiWho(articleTitle: title) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let response):
                wikiWhoResponse = response
            case .failure(let error):
                DDLogError(error)
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .default)) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            if let articleHtml = articleHtml,
                  let wikiWhoResponse = wikiWhoResponse {
               
                do {
                    try self.processContent(articleHtml: articleHtml, wikiWhoResponse: wikiWhoResponse)
                } catch (let error) {
                    DDLogError(error)
                }
                
            } else {
                DDLogError("Failure fetching articleHtml or wikiWhoResponse")
            }
        }
        
    }
    
    
    /// // Transforms article html, annotated WikiWho html and associated editor and revision information into combined structs for easier article content sentence highlighting and Article Inspector modal display.
    /// - Parameters:
    ///   - articleHtml: Article content html
    ///   - wikiWhoResponse: Decoded WikiWho data from labs WikiWho endpoint
    func processContent(articleHtml: String, wikiWhoResponse: WikiWhoResponse) throws {
        
        //TODO: Implementation
    }
}
