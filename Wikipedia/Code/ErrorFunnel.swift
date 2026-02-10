@objc(WMFErrorCategory) public enum Category: Int {
    case WMFData
    case WMFComponents
    case WMFFramework
    case AppSide
    
    var description: String {
        switch self {
        case .WMFData: return "WMFData"
        case .WMFComponents: return "WMFComponents"
        case .WMFFramework: return "WMFFramework"
        case .AppSide: return "AppSide"
        }
    }
}

@objc(WMFErrorFunnel) public final class ErrorFunnel: NSObject {
    
    @objc public static let shared = ErrorFunnel()
    
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
    
    @objc public func logEvent(domain: String, code: String, category: Category, details: [String: String]? = nil) {
        logEvent(domain: domain, code: code, category: category, details: details, project: nil)
    }
    
    public func logEvent(domain: String, code: String, category: Category, details: [String: String]? = nil, project: WikimediaProject? = nil) {
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
        let event = ErrorFunnel.Event(domain: domain, code: code, category: category.description, details: detailsString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .appError, event: event)
    }
}
