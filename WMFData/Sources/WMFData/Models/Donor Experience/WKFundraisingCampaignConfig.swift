import Foundation

public struct WKFundraisingCampaignConfig {
 
 public struct WKAsset {
     
     public struct WKAction {
         public let title: String
         public let url: URL?
     }
     
     public let id: String // Matches parent id
     public let textHtml: String
     public let footerHtml: String
     public let actions: [WKAction]
     public let countryCode: String
     public let currencyCode: String
     public let startDate: Date
     public let endDate: Date
     public let languageCode: String
 }
 
 public let id: String
 public let assets: [String: WKAsset]
}
