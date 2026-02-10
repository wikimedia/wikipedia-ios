import WMF

@objc final class ErrorFunnel: NSObject {
    
    @objc static let shared = ErrorFunnel()
    
    private struct Event: EventInterface {
        static let schema: WMF.EventPlatformClient.Schema = .appError
        
        let domain: String
        let code: String
        let category: String?
        let details: String?
        let platform: String
        let wikiID: String?
        
        enum CodingKeys: String, CodingKey {
            case domain = "domain"
            case code = "code"
            case category = "category"
            case details = "details"
            case platform = "platform"
            case wikiID = "wiki_id"
        }
    }
    
    public func logEvent(domain: String, code: String, category: String?, details: [String: String]? = nil, project: WikimediaProject? = nil) {
        var detailsString: String? = nil
        if let details {
            detailsString = ""
            for (key, value) in details {
                detailsString?.append("\(key):\(value), ")
            }
            
            if let finalDetailsString = detailsString,
               finalDetailsString.count > 1 {
                detailsString?.removeLast(2)
            }
        }
        let event = ErrorFunnel.Event(domain: domain, code: code, category: category, details: detailsString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .appActivityTab, event: event)
    }
}
