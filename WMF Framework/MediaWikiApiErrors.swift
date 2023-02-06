import Foundation

/// An object that is passed through from fetchers to view controllers, for reference when displaying errors in a panel.
@objc public class MediaWikiAPIDisplayError: NSObject {
    
    // Fully resolved html to display in the blocked panel.
    @objc public let messageHtml: String
    
    // Base url to be referenced when user taps a relative link within the messageHtml in the blocked panel.
    public let linkBaseURL: URL
    
    // Error code, passed through from original MediaWikiAPIError. Currently used for logging.
    public let code: String
    
    public init(messageHtml: String, linkBaseURL: URL, code: String) {
        self.messageHtml = messageHtml
        self.linkBaseURL = linkBaseURL
        self.code = code
    }
}


/// Represents errors that come in the MediaWiki API response.
/// See https://www.mediawiki.org/wiki/API:Errors_and_warnings
public struct MediaWikiAPIError: Codable {
 
    public struct Data: Codable {
        public struct BlockInfo: Codable {
            let blockreason: String
            let blockpartial: Bool
            let blockedby: String
            let blockid: Int64
            let blockexpiry: String
            let blockedtimestamp: String
            
            init?(dict: [String: Any]) {
                
                guard let blockReason = dict["blockreason"] as? String,
                let blockPartial = dict["blockpartial"] as? Bool,
                let blockedBy = dict["blockedby"] as? String,
                let blockID = dict["blockid"] as? Int64,
                let blockExpiry = dict["blockexpiry"] as? String,
                        let blockedTimestamp = dict["blockedtimestamp"] as? String else {
                    return nil
                }
                
                self.blockreason = blockReason
                self.blockpartial = blockPartial
                self.blockedby = blockedBy
                self.blockid = blockID
                self.blockexpiry = blockExpiry
                self.blockedtimestamp = blockedTimestamp
            }
        }
        
        let blockinfo: BlockInfo?
        
        init?(dict: [String: Any]) {
            
            guard let blockInfoDict = dict["blockinfo"] as? [String: Any] else {
                self.blockinfo = nil
                return
            }
            
            self.blockinfo = BlockInfo(dict: blockInfoDict)
        }
    }
    
    public let code: String
    let html: String
    let data: Data?
    
    init?(dict: [String: Any]) {
        
        guard let code = dict["code"] as? String,
              let html = dict["html"] as? String
         else {
            return nil
        }
        
        self.code = code
        self.html = html
        
        guard let dataDict = dict["data"] as? [String: Any] else {
            self.data = nil
            return
        }
        
        self.data = Data(dict: dataDict)
    }
}
