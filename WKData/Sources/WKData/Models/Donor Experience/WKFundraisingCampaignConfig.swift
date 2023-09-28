import Foundation

public struct WKFundraisingCampaignConfig {
 
 public struct WKAsset {
     
     public struct WKAction {
         let title: String
         let url: URL?
     }
     
     public let id: String // Matches parent id
     public let textHtml: String
     public let footerHtml: String
     public let actions: [WKAction]
     public let currencyCode: String
 }
 
 public let id: String
 public let assets: [String: WKAsset]
}
